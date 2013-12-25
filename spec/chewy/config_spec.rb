require 'spec_helper'

describe Chewy::Config do
  include ClassHelpers
  subject { described_class.send(:new) }

  describe '#atomic?' do
    its(:atomic?) { should be_false }
    specify { subject.atomic { subject.atomic?.should be_true } }
    specify { subject.atomic { }; subject.atomic?.should be_false }
  end

  describe '#atomic' do
    before do
      stub_index(:dummies) do
        define_type :dummy
      end
    end
    let(:dummy_type) { DummiesIndex::Dummy }

    specify { subject.atomic { 42 }.should == 42 }
    specify { expect { subject.atomic { subject.stash Class.new, 42 } }.to raise_error ArgumentError }
    specify { subject.atomic { subject.atomic { subject.stash.should == [{}, {}] } } }

    specify do
      expect(dummy_type).to receive(:import).with([1, 2, 3]).once
      subject.atomic do
        subject.stash dummy_type, [1, 2]
        subject.stash dummy_type, [2, 3]
      end
    end

    specify do
      expect(dummy_type).to receive(:import).with([1, 2]).once
      subject.atomic do
        subject.stash dummy_type, [1, 2]
        raise
      end rescue nil
    end

    specify do
      expect(dummy_type).to receive(:import).with([2, 3]).once
      expect(dummy_type).to receive(:import).with([1, 2]).once
      subject.atomic do
        subject.stash dummy_type, [2, 3]
        subject.atomic do
          subject.stash dummy_type, [1, 2]
        end
      end
    end
  end

  describe '#stash' do
    specify { subject.atomic { subject.stash.should == [{}] } }
  end
end
