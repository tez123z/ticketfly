module Ticketfly
  require 'open-uri'
  require 'json'
  
  class Header
    def self.random
      ["Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:43.0) Gecko/20100101 Firefox/43.0", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.11; rv:43.0) Gecko/20100101 Firefox/43.0", "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_2; de-at) AppleWebKit/531.21.8 (KHTML, like Gecko) Version/4.0.4 Safari/531.21.10", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Safari/601.3.9", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2486.0 Safari/537.36 Edge/13.10586", "Mozilla/5.0 (Windows NT 6.3; WOW64; rv:43.0) Gecko/20100101 Firefox/43.0"].sample
    end
  end

  class Org

    attr_accessor :id, :name, :json
    def self.build(json)
      org = Org.new
      org.id = json['id']
      org.name = json['name']
      org.promoter = json['promoter'] if json['promoter'] rescue {}
      org.json = json
      org
    end
  end  
  
  class Venue
    
    attr_accessor :id, :name, :json, :lat, :lon, :postalCode

    def self.build(json)
      venue = Venue.new
      venue.id = json['id']
      venue.name = json['name']
      venue.lat = json['lat']
      venue.lon = json['lng']
      venue.postalCode = json['postalCode']
      venue.json = json
      venue
    end
    
    def has_image?
      !self.json['image'].nil?
    end

    def image_url
      
      return "" unless self.has_image?

      url = ""
      width = 0
      height = 0

      self.json['image'].each do |key,image|
        
        if (image['width'].to_i * image['height'].to_i) > width * height
          url = image['path']
        end

      end

      url

    end

    def events
      Events.get_by_venue_id(self.id)
    end
    
    def next_event
      Events.get_next_by_venue_id(self.id)
    end
  end
  
  class Headliner

    attr_accessor :id, :name, :json, :twitterScreenName, :embedAudio, :embedVideo, :youtubeVideos

    def self.build(json)
      headliner = Headliner.new
      headliner.id = json['id']
      headliner.name = json['name']
      headliner.embedAudio = json['embedAudio']
      headliner.embedVideo = json['embedVideo']
      headliner.youtubeVideos = json['youtubeVideos']
      headliner.twitterScreenName = json['twitterScreenName']
      headliner.json = json
      headliner
    end

    def has_image?
      !self.json['image'].nil?
    end

    def image_url
      
      return "" unless self.has_image?
      
      url = ""
      width = 0
      height = 0

      self.json['image'].each do |key,image|
        
        if (image['width'].to_i * image['height'].to_i) > width * height
          url = image['path']
        end

      end

      url

    end

  end

  class Event

    attr_accessor :id, :name, :venue, :org, :eventStatusCode, :date, :json, :ticketPurchaseUrl, :urlEventDetailsUrl, :headlinersName, :supportsName, :startDate, :endDate, :doorsDate, :onSaleDate, :offSaleDate, :ticketPrice, :urlEventDetailsUrl, :showType, :showTypeCode
    
    def self.build(json)
      event = Event.new
      event.id = json['id']
      event.name = json['name']
      event.json = json
      event.venue = Venue.build(json['venue'])
      event.org = Org.build(json['org'])
      event.eventStatusCode = json['eventStatusCode']
      event.date = json['startDate']
      event.ticketPurchaseUrl = json['ticketPurchaseUrl']
      event.urlEventDetailsUrl = json['urlEventDetailsUrl']
      event.headlinersName = json['headlinersName'] 
      event.supportsName = json['supportsName']
      event.startDate = json['startDate']
      event.endDate = json['endDate']
      event.doorsDate = json['doorsDate']
      event.onSaleDate = json['onSaleDate']
      event.offSaleDate = json['offSaleDate']
      event.ticketPrice = json['ticketPrice']
      event.urlEventDetailsUrl = json['urlEventDetailsUrl']
      event.showType = json['showType']
      event.showTypeCode = json['showTypeCode']
      event
    end
    
    def is_soldout?
      self.eventStatusCode == "SOLD_OUT" || self.eventStatusCode == "OFF_SALE"
    end

    def tickets_at_door?
      self.eventStatusCode == "TIX_AT_DOOR"
    end

    def etickets_available?
      self.eventStatusCode == "BUY"
    end

    def is_cancelled?
      self.eventStatusCode == "CANCELLED"
    end

    def is_postponed?
      self.eventStatusCode == "POSTPONED"
    end

    def is_free?
      self.ticketPrice == "Free"
    end

    def has_image?
      !self.json['image'].nil?
    end

    def image_url
      
      return "" unless self.has_image?
      
      url = ""
      width = 0
      height = 0

      self.json['image'].each do |key,image|
        
        if (image['width'].to_i * image['height'].to_i) > width * height
          url = image['path']
        end

      end

      url

    end

    def headliners
      headliners = []
      self.json['headliners'].each do |h|
        headliners << Headliner.build(h)
      end
      headliners
    end
  end

  class Events
    
    def self.get_all
      max_results = 1000
      events = []
      total_pages = 1
      page = 1
      begin
        base_uri = "https://www.ticketfly.com/api/events/upcoming.json"
        result = JSON.parse(open(base_uri + "?orgId=1&maxResults=" + max_results.to_s + "&pageNum=" + page.to_s,"User-Agent" => Header.random).read)
        total_pages = result["totalPages"]
        result['events'].each do |e|
          event = Event.build(e)
          events << event
        end
        page += 1
      end while not page > total_pages
      events
    end

    def self.get_by_id(id)
      base_uri = "https://www.ticketfly.com/api/events/list.json"
      max_results = 1
      result = JSON.parse(open(base_uri + "?orgId=1&eventId=" + id.to_s,"User-Agent" => Header.random).read)
      return nil if result['events'].count == 0
      Event.build(result['events'].first)
    end
    
    def self.get_next_by_venue_id(venue_id)
      base_uri = "https://www.ticketfly.com/api/events/upcoming.json"
      max_results = 1
      result = JSON.parse(open(base_uri + "?orgId=1&venueId=" + venue_id.to_s,"User-Agent" => Header.random).read)
      Event.build(result['events'].first)
    end
    
    def self.get_by_venue_id(venue_id)
      base_uri = "https://www.ticketfly.com/api/events/upcoming.json"
      max_results = 200
      events = []
      total_pages = 1
      page = 1
      begin
        result = JSON.parse(open(base_uri + "?orgId=1&venueId=" + venue_id.to_s,"User-Agent" => Header.random).read)
        total_pages = result["totalPages"]
        result['events'].each do |e|
          event = Event.build(e)
          events << event
        end
        page += 1
      end while not page > total_pages
      events
    end
    
    def self.search(query)
      base_uri = "https://www.ticketfly.com/api/events/upcoming.json"
      max_results = 5
      events = []
      total_pages = 1
      page = 1
      begin
        result = JSON.parse(open(base_uri + "?orgId=1&q=" + query.to_s + "&maxResults=" + max_results.to_s,"User-Agent" => Header.random).read)
        total_pages = result["totalPages"]
        result['events'].each do |e|
          event = Event.build(e)
          events << event
        end
        page += 1
      end while not page > total_pages
      events
    end
  end
  
  
  class Orgs

    def self.get_all
      base_uri = "https://www.ticketfly.com/api/orgs/list.json"
      max_results = 200
      orgs = []
      total_pages = 1
      page = 1
      begin
        result = JSON.parse(open(base_uri + "?maxResults=" + max_results.to_s + "&pageNum=" + page.to_s,"User-Agent" => Header.random).read)
        total_pages = result["totalPages"]
        result['orgs'].each do |o|
          org = Org.build(o)
          orgs << org
        end
        page += 1
      end while not page > total_pages
      orgs
    end
  end
  
  class Venues

    def self.get(id)
      max_results = 200
      venues = []
      total_pages = 1
      page = 1
      begin
        base_uri = "https://www.ticketfly.com/api/venues/list.json"
        result = JSON.parse(open(base_uri + "?orgId=1&venueId=" + id.to_s,"User-Agent" => Header.random).read)
        total_pages = result["totalPages"]
        result['venues'].each do |v|
          venue = Venue.build(v)
          venues << venue
        end
        page += 1
      end while not page > total_pages
      venues[0]
    end

    def self.get_all
      max_results = 200
      venues = []
      total_pages = 1
      page = 1
      begin
        base_uri = "https://www.ticketfly.com/api/venues/list.json"
        result = JSON.parse(open(base_uri + "?orgId=1&maxResults=" + max_results.to_s + "&pageNum=" + page.to_s,"User-Agent" => Header.random).read)
        total_pages = result["totalPages"]
        result['venues'].each do |v|
          venue = Venue.build(v)
          venues << venue
        end
        page += 1
      end while not page > total_pages
      venues
    end

    def self.search(query)
      base_uri = "https://www.ticketfly.com/api/venues/list.json"
      max_results = 5
      venues = []
      total_pages = 1
      page = 1
      begin
        result = JSON.parse(open(base_uri + "?orgId=1&q=" + query.to_s + "&maxResults=" + max_results.to_s,"User-Agent" => Header.random).read)
        total_pages = result["totalPages"]
        result['venues'].each do |v|
          venue = Venue.build(v)
          venues << venue
        end
        page += 1
      end while not page > total_pages
      venues
    end

  end
end