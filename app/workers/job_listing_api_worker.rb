# This worker queries the API for potential users that will be shown to a company
class JobListingAPIWorker
  include Sidekiq::Worker

  def perform(id)
    job_listing = JobListing.find(id)
    job_listing.api_retrieve(self.api_attributes, 'preferences') if job_listing
  end
end
