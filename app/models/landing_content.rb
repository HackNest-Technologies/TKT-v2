# Content for the landing page.
#
# SAMPLE DATA: stream, Trybe, testimony and post entries below are the design's
# placeholder content. They are replaced by database records in later stages
# (streams: Stage 6, Trybes/posts/testimonies: Stage 7). Testimony names must
# not be published without the named people's written consent.
class LandingContent
  Stream = Data.define(:title, :live, :viewers_label)
  Trybe  = Data.define(:name, :members_label, :description)
  Quote  = Data.define(:text, :author)
  Post   = Data.define(:title, :excerpt, :meta, :tag)

  def featured_stream
    Stream.new(title: "Joy Stream — ‘Finding Hope’", live: true, viewers_label: "2.4k watching")
  end

  def trybes
    [
      Trybe.new(name: "AFK with God", members_label: "Live sessions", description: "Fireside / listening sessions"),
      Trybe.new(name: "Main Trybe Hub", members_label: "1.2k members", description: "Announcements, devotionals, platform updates"),
      Trybe.new(name: "Mentorship Group", members_label: "96 members", description: "1:1 and small group mentoring"),
      Trybe.new(name: "Testimony Sharing", members_label: "512 members", description: "Share your journey and encourage others")
    ]
  end

  def testimonies
    [
      Quote.new(text: "The online services have been a blessing, especially during the pandemic when we couldn't attend church physically. God is truly using this ministry.", author: "Adebayo Ogunlesi"),
      Quote.new(text: "After attending the prayer conference, my business turned around miraculously. I went from nearly bankrupt to profitable in three months!", author: "David Chukwu"),
      Quote.new(text: "I received healing from a chronic illness after the ministers prayed for me. The doctors can't explain it, but I know it was God's power.", author: "Emeka Nwachukwu")
    ]
  end

  def featured_post
    Post.new(
      title: "When worship feels like your favorite stream",
      excerpt: "Digital doesn’t have to be distant. Here’s how to stay present in online services — setting up your space, choosing intentional moments to respond, and using the community tools (chat, clips, devotion drops) so you’re not just watching a screen but actually worshipping with everyone else in real time.",
      meta: "4 min read · Oct 12, 2025",
      tag: "Latest"
    )
  end
end
