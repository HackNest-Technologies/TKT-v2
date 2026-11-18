module NavigationHelper
  def primary_nav_items
    [
      [ "Watch", watch_path ],
      [ "Community", community_path ],
      [ "Counselling", support_path ],
      [ "Give", give_path ],
      [ "Resources", blog_path ],
      [ "Store", store_path ]
    ]
  end

  # Social links are placeholders until the real profile URLs are provided.
  def footer_columns
    [
      [ "Platform", [ [ "Watch", watch_path ], [ "Community", community_path ], [ "Counselling", support_path ], [ "Team", team_path ] ] ],
      [ "Resources", [ [ "Blog", blog_path ], [ "Events", events_path ], [ "Past Sermons", watch_path ], [ "Daily devotion", devotions_path ] ] ],
      [ "Participate", [ [ "Give", give_path ], [ "Merch", store_path ], [ "Share Testimony", share_testimony_path ] ] ],
      [ "Socials", [ [ "Instagram", social_path("instagram") ], [ "Facebook", social_path("facebook") ], [ "Tik Tok", social_path("tiktok") ], [ "Youtube", social_path("youtube") ] ] ],
      [ "Legal", [ [ "Privacy policy", privacy_path ], [ "Terms of Use", terms_path ] ] ]
    ]
  end

  def social_path(_network)
    community_path
  end
end
