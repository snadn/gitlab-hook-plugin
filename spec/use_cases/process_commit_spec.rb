require 'spec_helper'

module GitlabWebHook
  describe ProcessCommit do
    include_context 'settings'
    include_context 'projects'
    include_context 'details'

    let(:action) { double(Proc) }
    let(:create_project_for_branch) { double(CreateProjectForBranch) }

    before :each do
      expect(CreateProjectForBranch).to receive(:new).and_return( create_project_for_branch )
    end

    context 'with related projects' do

      let(:projects_matching_uri) { [ matching_project , not_matching_project ] }

      before :each do
        expect(matching_project.matches_uri?(details.repository_uri)).to be(true)
        expect(not_matching_project.matches_uri?(details.repository_uri)).to be(true)
        expect(autocreate_match_project.matches_uri?(details.repository_uri)).to be(false)
      end

      it 'calls action with found project and related details' do
        expect(action).to receive(:call).once.with(matching_project, details)
        subject.with(details, projects_matching_uri, action)
      end

      it 'returns messages collected by calls to action' do
        expect(action).to receive(:call).once.with(matching_project, details).and_return('executed')
        messages = subject.with(details, projects_matching_uri, action)
        expect(messages.size).to eq(1)
        expect(messages).to eq(%w(executed))
      end

      context 'when automatic project creation is on' do
        let(:new_project) { double(Project) }
        before(:each) { allow(settings).to receive(:automatic_project_creation?) { true } }

        it 'searches exactly matching projects' do
          expect(create_project_for_branch).not_to receive(:with)
          expect(action).to receive(:call).once
          subject.with(details, projects_matching_uri, action)
        end

        it 'creates a new project when no matching projects found' do
          expect(create_project_for_branch).to receive(:with).with(details).and_return(new_project)
          expect(action).to receive(:call).once.with(new_project, details).once
          subject.with(details, [ not_matching_project ] , action)
        end
      end
    end

    context 'with push from unknown repository' do
      let(:new_project) { double(Project) }
      let(:templated_jobs) { { 'matchstr' => 'job-template'} }
      let(:templated_groups) { { 'matchstr' => 'group-template'} }

      before(:each) do
        allow(settings).to receive(:templated_jobs).and_return( templated_jobs )
        allow(settings).to receive(:templated_groups).and_return( templated_groups )
      end

      context 'and a template matches repository name' do
        let(:templated_jobs) { { 'Dias' => 'reponame-template'} }

        it 'returns the jobname template' do
          expect(settings).not_to receive(:templated_groups)
          expect(settings).not_to receive(:template_fallback)
          expect(create_project_for_branch).to receive(:from_template).with('reponame-template', details).and_return(new_project)
          expect(action).to receive(:call)
          subject.with(details, [], action)
        end
      end

      context 'and repo namespace matches some template' do
        let(:templated_groups) { { 'mike' => 'repogroup-template' } }

        it 'returns the groupname template' do
          expect(settings).not_to receive(:template_fallback)
          expect(create_project_for_branch).to receive(:from_template).with('repogroup-template', details).and_return(new_project)
          expect(action).to receive(:call)
          subject.with(details, [], action)
        end
      end

      context 'and fallback template exists' do
        it 'returns the groupname template' do
          expect(settings).to receive(:template_fallback).twice.and_return( 'fallback-template' )
          expect(create_project_for_branch).to receive(:from_template).with('fallback-template', details).and_return(new_project)
          expect(action).to receive(:call)
          subject.with(details, [], action)
        end
      end

      it 'raises exception when no matching projects found' do
        expect(action).not_to receive(:call)
        expect { subject.with(details, [], action) }.to raise_exception(NotFoundException)
      end

    end
  end
end
