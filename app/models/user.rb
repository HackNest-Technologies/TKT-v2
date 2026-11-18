class User < ApplicationRecord
  MINIMUM_AGE = 16
  ADULT_AGE = 18
  RESERVED_HANDLES = %w[admin administrator root support help tkt kingdomtrybe trybe staff moderator mod
                        system api www mail security pastor official null undefined].freeze
  CONSENT_VERSION = "2026-11-09"

  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :omniauthable, omniauth_providers: [ :google_oauth2 ]

  has_many :identities, dependent: :delete_all
  has_many :user_sessions, dependent: :delete_all
  has_many :consents, dependent: :delete_all

  # Form-only attributes for sign-up and profile completion.
  attribute :accept_terms, :boolean
  attribute :accept_sensitive_data, :boolean
  attribute :confirm_minimum_age, :boolean

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }
  normalizes :handle, with: ->(handle) { handle.to_s.strip.delete_prefix("@").presence }

  validates :handle, format: { with: /\A[A-Za-z0-9_]{3,20}\z/, message: "must be 3–20 letters, numbers or underscores" },
                     uniqueness: { case_sensitive: false }, allow_nil: true
  validate :handle_not_reserved
  validates :birth_year, numericality: { only_integer: true, greater_than_or_equal_to: 1900, less_than_or_equal_to: ->(_) { Date.current.year } }, allow_nil: true
  validate :meets_minimum_age, if: -> { birth_year.present? }

  # Sign-up (email) and profile completion (Google) collect age and consents.
  with_options on: [ :registration, :profile ] do
    validates :birth_year, presence: true, unless: :birth_year_was_present?
    validates :confirm_minimum_age, acceptance: { accept: true, message: "must be confirmed" }, if: :collecting_age?
    validates :accept_terms, acceptance: { accept: true, message: "must be accepted to create an account" }, if: -> { terms_accepted_at.blank? }
    validates :accept_sensitive_data, acceptance: { accept: true, message: "is needed because joining TKT shows a religious affiliation" }, if: -> { sensitive_data_consent_at.blank? }
  end
  validates :handle, presence: true, on: :profile

  before_save :stamp_consents
  after_save :record_consents
  after_update :revoke_sessions_after_password_change, if: :saved_change_to_encrypted_password?

  def self.under_minimum_age?(year)
    year.to_i.positive? && (Date.current.year - year.to_i) < MINIMUM_AGE
  end

  def profile_incomplete?
    handle.blank? || birth_year.blank? || terms_accepted_at.blank? || sensitive_data_consent_at.blank?
  end

  # Under 18: still a child under Nigerian data law; used to apply stricter defaults later.
  def minor?
    birth_year.present? && (Date.current.year - birth_year) < ADULT_AGE
  end

  # Members who joined with Google have a random password they never saw.
  def google_only? = identities.exists?(provider: "google_oauth2")

  # Accounts awaiting deletion cannot sign in (30-day purge window).
  def active_for_authentication?
    super && deletion_requested_at.nil?
  end

  def inactive_message
    deletion_requested_at.present? ? :deletion_requested : super
  end

  def request_deletion!
    transaction do
      update_columns(deletion_requested_at: Time.current, updated_at: Time.current)
      revoke_all_sessions!
    end
  end

  def revoke_all_sessions!(except: nil)
    scope = user_sessions.active
    scope = scope.where.not(id: except.id) if except
    scope.update_all(revoked_at: Time.current, updated_at: Time.current)
    forget_me! # invalidates "remember me" cookies on every device
  end

  # Devise: send mail in the background.
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  # Data export (member right): everything we hold about this account, no secrets.
  def export_data
    {
      exported_at: Time.current.iso8601,
      account: {
        email: email, handle: handle, birth_year: birth_year, created_at: created_at.iso8601,
        confirmed_at: confirmed_at&.iso8601, terms_accepted_at: terms_accepted_at&.iso8601,
        sensitive_data_consent_at: sensitive_data_consent_at&.iso8601
      },
      sign_in_methods: [ ("password" if encrypted_password.present?), *identities.pluck(:provider) ].compact,
      consents: consents.order(:granted_at).map { |c| c.slice(:purpose, :version, :granted_at, :withdrawn_at) },
      sessions: user_sessions.order(created_at: :desc).map { |s| s.slice(:user_agent, :created_at, :last_seen_at, :revoked_at) }
    }
  end

  private

  def birth_year_was_present? = birth_year_in_database.present?
  def collecting_age? = birth_year_in_database.blank?

  def handle_not_reserved
    errors.add(:handle, "is not available") if handle.present? && RESERVED_HANDLES.include?(handle.downcase)
  end

  def meets_minimum_age
    errors.add(:birth_year, "shows you are under #{MINIMUM_AGE}. TKT accounts are for people aged #{MINIMUM_AGE} and over") if self.class.under_minimum_age?(birth_year)
  end

  def stamp_consents
    self.terms_accepted_at ||= Time.current if accept_terms
    self.sensitive_data_consent_at ||= Time.current if accept_sensitive_data
  end

  def record_consents
    now = Time.current
    consents.create!(purpose: "terms_and_privacy", version: CONSENT_VERSION, granted_at: now) if saved_change_to_terms_accepted_at? && terms_accepted_at
    consents.create!(purpose: "sensitive_data_processing", version: CONSENT_VERSION, granted_at: now) if saved_change_to_sensitive_data_consent_at? && sensitive_data_consent_at
  end

  def revoke_sessions_after_password_change
    revoke_all_sessions!
  end
end
