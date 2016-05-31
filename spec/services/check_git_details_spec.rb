require 'spec_helper'

module GitlabWebHook
  describe CheckGitDetails do
    include_context 'settings'

    let(:details) { double(RequestDetails, user_name: '') }

    context 'when validating' do
      it 'requires details' do
        expect { subject.with(nil) }.to raise_exception(ArgumentError)
      end
    end

    context 'with no username' do
      include_context 'details'
      it 'returns nil' do
        error = subject.with(details)
        expect(error).to be_nil
      end
    end

    context 'with allowed username' do
      include_context 'details'
      it 'returns nil' do
        allow(details).to receive(:user_name) { 'user 7' }
        error = subject.with(details)
        expect(error).to be_nil
      end
    end

    context 'with disallowed username' do
      include_context 'details'
      it 'returns an error message' do
        allow(details).to receive(:user_name) { 'user 2' }
        error = subject.with(details)
        expect(error).to match('Not processing request for a git action by')
      end
    end

  end
end
