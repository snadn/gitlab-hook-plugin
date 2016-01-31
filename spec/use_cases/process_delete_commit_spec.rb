require 'spec_helper'

module GitlabWebHook
  describe ProcessDeleteCommit do
    include_context 'settings'

    let(:details) { double(RequestDetails, branch: 'features/meta', repository_uri: 'git@gitlab.com/group/discourse') }

    context 'when automatic project creation is offline' do
      let(:project) { double(Project) }
      before(:each) { allow(settings).to receive(:automatic_project_creation?) { false } }

      it 'skips processing' do
        expect(subject.with(details, [project]).first).to match('automatic branch projects creation is not active')
      end
    end

    context 'when automatic project creation is online' do
      before(:each) { allow(settings).to receive(:automatic_project_creation?) { true } }

      context 'with master branch in commit' do
        let(:project) { double(Project) }

        it 'skips processing' do
          allow(details).to receive(:branch) { settings.master_branch }
          expect(subject.with(details, [project]).first).to match('relates to master project')
        end
      end

      context 'with non master branch in commit' do
        let(:project) { double(Project, to_s: 'non_master') }

        before(:each) do
          allow(project).to receive(:matches?) { true }
        end

        it 'deletes automatically created project' do
          allow(project).to receive(:description) { settings.description }
          expect(project).to receive(:delete)
          expect(subject.with(details, [project]).first).to match("deleted #{project} project")
        end

        it 'skips project not automatically created' do
          allow(project).to receive(:description) { 'manually created' }
          expect(project).not_to receive(:delete)
          expect(subject.with(details, [project]).first).to match('not automatically created')
        end
      end
    end
  end
end
