describe Robots::SdrRepo::PreservationIngest::CompleteIngest do
  let(:bare_druid) { 'jc837rq9922' }
  let(:druid) { "druid:#{bare_druid}" }
  let(:deposit_dir_pathname) { Pathname(File.join(File.dirname(__FILE__), '..', 'fixtures', 'deposit', 'complete-ingest')) }
  let(:deposit_bag_pathname) { Pathname(File.join(deposit_dir_pathname, bare_druid)) }
  let(:mock_so) { instance_double(Moab::StorageObject, deposit_bag_pathname: deposit_bag_pathname) }
  let(:this_robot) { described_class.new }

  context '#perform' do
    before do
      allow(deposit_bag_pathname).to receive(:rmtree)
      allow(Moab::StorageServices).to receive(:find_storage_object).and_return(mock_so)
      FileUtils.mkdir_p(deposit_bag_pathname)
      FileUtils.touch(deposit_bag_pathname + 'bagit_file.txt')
    end
    after do
      deposit_dir_pathname.rmtree if deposit_dir_pathname.exist?
    end

    it 'raises ItemError if it fails to remove the deposit bag' do
      expect(deposit_bag_pathname.exist?).to be true
      expect(deposit_bag_pathname).to receive(:rmtree).and_raise(StandardError, 'rmtree failed')
      exp_msg = Regexp.escape("Error completing ingest for #{druid}: failed to remove deposit bag (#{deposit_bag_pathname}): rmtree failed")
      expect { this_robot.perform(druid) }.to raise_error(Robots::SdrRepo::PreservationIngest::ItemError, a_string_matching(exp_msg))
      expect(deposit_bag_pathname.exist?).to be true
    end

    it 'raises ItemError if it fails to update the accessionWF sdr-ingest-received step' do
      error = Dor::WorkflowException.new('foo')
      expect(Dor::Config.workflow.client).to receive(:update_workflow_status)
        .with('dor', druid, 'accessionWF', 'sdr-ingest-received', 'completed', instance_of(Hash)).and_raise(error)
      exp_msg = Regexp.escape("Error completing ingest for #{druid}: failed to update accessionWF:sdr-ingest-received to completed: ") + ".*foo"
      expect { this_robot.perform(druid) }.to raise_error(Robots::SdrRepo::PreservationIngest::ItemError, a_string_matching(exp_msg))
    end

    it 'removes the deposit bag and updates the accessionWF when no errors are raised' do
      expect(deposit_bag_pathname).to receive(:rmtree)
      expect(Dor::Config.workflow.client).to receive(:update_workflow_status)
        .with('dor', druid, 'accessionWF', 'sdr-ingest-received', 'completed', instance_of(Hash))
      expect { this_robot.perform(druid) }.not_to raise_error
    end
  end
end
