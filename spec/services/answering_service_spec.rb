require 'spec_helper'

describe 'AnsweringService' do
  let!(:minister1) { create(:minister, member_id: 1) }
  let(:uin) { '183366' }

  before(:each) do
    @http_client = double('QuestionsHttpClient')
    allow(@http_client).to receive(:answer) { {content: sample_answer, status: 200} }
    allow(@http_client).to receive(:question) { sample_question_for_answer }

    @questions_service = QuestionsService.new(@http_client)
    @answering_service = AnsweringService.new(@questions_service)
    @import_service = ImportService.new(@questions_service)
  end

  describe '#answer' do
    it 'should insert the answer url in the pq' do
      @import_service.questions_by_uin(uin)

      pq = Pq.find_by(uin: uin)
      pq.minister = minister1

      @answering_service.answer(pq, {text: 'Hello test', is_holding_answer: true})

      pq = Pq.find_by(uin: uin)
      expect(pq.preview_url).to eq('https://wqatest.parliament.uk/Questions/Details/36527')
    end

    it 'should raise an exception if the minister is nil' do
      @import_service.questions_by_uin(uin)

      pq = Pq.find_by(uin: uin)

      expect {
        @answering_service.answer(pq, {text: 'Hello test', is_holding_answer: true})
      }.to raise_error 'Replying minister is not selected for the question'
    end

    it 'should raise an exception if the member id is nil' do
      @import_service.questions_by_uin(uin)

      pq = Pq.find_by(uin: uin)
      pq.minister = minister1
      pq.minister.member_id = nil

      expect {
        @answering_service.answer(pq, {text: 'Hello test', is_holding_answer: true})
      }.to raise_error 'Replying minister has not member id, please update the member id of the minister'
    end


    it 'should raise an exception you have a error in questions_service' do
      allow(@http_client).to receive(:answer) { {content: sample_answer_error, status: 403} }

      @import_service.questions_by_uin(uin)

      pq = Pq.find_by(uin: uin)
      pq.minister = minister1

      expect {
        @answering_service.answer(pq, {text: 'Hello test', is_holding_answer: true})
      }.to raise_error 'Validation failed on the request.'
    end
  end
end
