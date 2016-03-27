RSpec.shared_context 'details' do
  let (:payload) { JSON.parse(File.read('spec/fixtures/8x/push.json')) }
  let (:details) { GitlabWebHook::PayloadRequestDetails.new(payload) }
end
