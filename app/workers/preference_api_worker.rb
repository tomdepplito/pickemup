# Thia worker queries the API for potential job listings that will be shown to the developer
class PrefernceAPIWorker
  include Sidekiq::Worker

  def perform(id)
    preference = Preference.find(id)
    prefernce.api_retrieve(self.api_attributes, 'job_listings') if preference
  end
end
