require 'spec_helper'

module GitlabWebHook
  describe MergeRequestDetails do

    include_context 'mr_details'
    let (:subject) { MergeRequestDetails.new(mr_payload) }

    context 'when initializing' do
      it 'requires payload data' do
        expect { MergeRequestDetails.new(nil) }.to raise_exception(ArgumentError)
      end
      it 'raise exception for cross-repo merge requests' do
        mr_payload['object_attributes']['target_project_id'] = '15'
        expect { MergeRequestDetails.new(mr_payload) }.to raise_exception(BadRequestException)
      end
    end

    it '#kind is merge request' do
      expect(subject.kind).to eq('merge_request')
    end

    context '#project_id' do
      it 'parsed from payload' do
        expect(subject.project_id).to eq('14')
      end

      it 'returns empty when no source project found' do
        mr_payload['object_attributes'].delete('source_project_id')
        mr_payload['object_attributes'].delete('target_project_id')
        expect(subject.project_id).to eq('')
      end
    end

    context do
      before :each do
        allow(subject).to receive(:get_project_details).once.and_return( {
             'name' => 'diaspora' ,
             'web_url' => 'http://localhost/peronospora',
             'ssh_url_to_repo' => 'git@localhost:peronospora.git' } )
      end

      it '#repository_url returns ssh url for repository' do
        expect(subject.repository_url).to eq('git@example.com:awesome_space/awesome_project.git')
      end

      it '#repository_name returns repository name' do
        expect(subject.repository_name).to eq('Awesome Project')
      end

      it '#repository_homepage returns homepage for repository' do
        expect(subject.repository_homepage).to eq('http://example.com/awesome_space/awesome_project')
      end

    end

    context '#branch' do
      it 'returns source branch' do
        expect(subject.branch).to eq('ms-viewport')
      end

      it 'returns empty when no source branch found' do
        mr_payload['object_attributes'].delete('source_branch')
        expect(subject.branch).to eq('')
      end
    end

    context '#target_project_id' do
      it 'parsed from payload' do
        expect(subject.target_project_id).to eq('14')
      end

      it 'returns empty when no target project found' do
        mr_payload['object_attributes'].delete('source_project_id')
        mr_payload['object_attributes'].delete('target_project_id')
        expect(subject.target_project_id).to eq('')
      end
    end

    context '#target_branch' do
      it 'parsed from payload' do
        expect(subject.target_branch).to eq('master')
      end

      it 'returns empty when no target branch found' do
        mr_payload['object_attributes'].delete('target_branch')
        expect(subject.target_branch).to eq('')
      end
    end

    context '#state' do
      it 'parsed from payload' do
        expect(subject.state).to eq('opened')
      end

      it 'returns empty when no state data found' do
        mr_payload['object_attributes'].delete('state')
        expect(subject.state).to eq('')
      end
    end

    context '#merge_status' do
      it 'parsed from payload' do
        expect(subject.merge_status).to eq('unchecked')
      end

      it 'returns empty when no merge status data found' do
        mr_payload['object_attributes'].delete('merge_status')
        expect(subject.merge_status).to eq('')
      end
    end

    context '#repository_url' do
      it 'returns ssh url for repository' do
        expect(subject.repository_url).to eq('git@example.com:awesome_space/awesome_project.git')
      end
    end

    context '#repository_name' do
      it 'returns repository name' do
        expect(subject.repository_name).to eq('Awesome Project')
      end
    end

    context '#repository_homepage' do
      it 'returns homepage for repository' do
        expect(subject.repository_homepage).to eq('http://example.com/awesome_space/awesome_project')
      end
    end

  end
end
