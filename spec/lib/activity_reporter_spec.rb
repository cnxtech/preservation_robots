require "activity_reporter"
describe ActivityReporter do
  let(:date) { "2017-04-27" }
  let(:activity_reporter) { described_class.new }
  let(:base_path) { "#{Dir.pwd}/spec/fixtures" }
  let(:error_path) { "#{base_path}/log/sdr_preservationIngestWF_transfer-object.log" }
  let(:happy_path) { "#{base_path}/log/sdr_preservationIngestWF_validate-bag.log" }
  let(:dbl_date) { instance_double(Time, to_date: date) }
  let(:output) { activity_reporter.output }

  describe "#output" do
    before do
      allow(STDOUT).to receive(:puts).with("********************")
    end
    context "file does not exist" do
      before do
        allow(activity_reporter).to receive(:default_log_files).and_return(["/fake/file/path"])
      end
      it 'prints out expected message' do
        expect(STDOUT).to receive(:puts).with('EMPTY or NON-EXISTENT: /fake/file/path')
        output
      end
    end
    context "file exists" do
      before do
        allow(activity_reporter).to receive(:default_log_files).and_return([error_path])
      end
      context "file contains todays date" do
        before do
          allow(Time).to receive(:now).and_return(dbl_date)
        end
        context 'file contains /bundle/ruby|/usr/local/rvm|resque-signals/' do
          it 'prints out expected message' do
            expect(STDOUT).to receive(:puts).with("No activity 2017-04-27, DRUID count: 0\n")
            output
          end
        end
        context 'file does not contain /bundle/ruby|/usr/local/rvm|resque-signals/' do
          before do
            allow(activity_reporter).to receive(:default_log_files).and_return([happy_path])
          end
          context 'number of druids are returned' do
            it 'prints out expected message w/ only unique druids' do
              expect(STDOUT).to receive(:puts).with("DRUID count: 2 for #{date}\n")
              output
            end
          end
        end
      end
      context "file does not contain todays date" do
        before do
          allow(Time).to receive(:now).and_return("2017-05-01")
        end
        it 'prints out expected message' do
          expect(STDOUT).to receive(:puts).with("No activity 2017-05-01, DRUID count: 0\n")
          output
        end
      end
    end
  end
end
