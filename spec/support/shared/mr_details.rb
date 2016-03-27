RSpec.shared_context 'mr_details' do
  let (:mr_payload) { JSON.parse(File.read('spec/fixtures/8x/merge_request.json')) }
  let (:mr_details) { GitlabWebHook::MergeRequestDetails.new(mr_payload) }
end
