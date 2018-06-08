require 'spec_helper'
require 'open3'

RSpec.describe 'a type with composite namevars' do
  let(:common_args) { '--verbose --trace --debug --strict=error --modulepath spec/fixtures' }

  describe 'using `puppet resource`' do
    it 'is returns the values correctly' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} composite_namevar")
      expect(stdout_str.strip).to match %r{^composite_namevar}
      expect(status).to eq 0
    end
    it 'returns the required resource correctly' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} composite_namevar php-yum")
      expect(stdout_str.strip).to match %r{^composite_namevar \{ \'php-yum\'}
      expect(stdout_str.strip).to match %r{ensure\s*=> \'present\'}
      expect(stdout_str.strip).to match %r{package\s*=> \'php\'}
      expect(stdout_str.strip).to match %r{manager\s*=> \'yum\'}
      expect(status).to eq 0
    end
    it 'returns the required resource correctly, if title is not a matching title_pattern' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} composite_namevar foo package=php manager=yum")
      expect(stdout_str.strip).to match %r{^composite_namevar \{ \'foo\'}
      expect(stdout_str.strip).to match %r{ensure\s*=> \'present\'}
      expect(stdout_str.strip).to match %r{package\s*=> \'php\'}
      expect(stdout_str.strip).to match %r{manager\s*=> \'yum\'}
      expect(status).to eq 0
    end
    it 'returns the match if alternative title_pattern matches a single namevar and other namevars are present' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} composite_namevar php manager=gem")
      expect(stdout_str.strip).to match %r{^composite_namevar \{ \'php\'}
      expect(stdout_str.strip).to match %r{ensure\s*=> \'present\'}
      expect(status).to eq 0
    end
    it 'returns the match if title matches a namevar value' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} composite_namevar php")
      expect(stdout_str.strip).to match %r{^composite_namevar \{ \'php\'}
      expect(stdout_str.strip).to match %r{ensure\s*=> \'present\'}
      expect(status).to eq 0
    end
    it 'properly identifies an absent resource if only the title is provided' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} composite_namevar php-wibble")
      expect(stdout_str.strip).to match %r{^composite_namevar \{ \'php-wibble\'}
      expect(stdout_str.strip).to match %r{ensure\s*=> \'absent\'}
      expect(status).to eq 0
    end
    it 'creates a previously absent resource' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} composite_namevar php-wibble ensure='present'")
      expect(stdout_str.strip).to match %r{^composite_namevar \{ \'php-wibble\'}
      expect(stdout_str.strip).to match %r{ensure\s*=> \'present\'}
      expect(stdout_str.strip).to match %r{package\s*=> \'php\'}
      expect(stdout_str.strip).to match %r{manager\s*=> \'wibble\'}
      expect(status).to eq 0
    end
    it 'will remove an existing resource' do
      stdout_str, status = Open3.capture2e("puppet resource #{common_args} composite_namevar php-gem ensure=absent")
      expect(stdout_str.strip).to match %r{^composite_namevar \{ \'php-gem\'}
      expect(stdout_str.strip).to match %r{package\s*=> \'php\'}
      expect(stdout_str.strip).to match %r{manager\s*=> \'gem\'}
      expect(stdout_str.strip).to match %r{ensure\s*=> \'absent\'}
      expect(status).to eq 0
    end
  end

  describe 'using `puppet apply`' do
    require 'tempfile'

    let(:common_args) { super() + ' --detailed-exitcodes' }

    # run Open3.capture2e only once to get both output, and exitcode # rubocop:disable RSpec/InstanceVariable
    before(:each) do
      Tempfile.create('acceptance') do |f|
        f.write(manifest)
        f.close
        @stdout_str, @status = Open3.capture2e("puppet apply #{common_args} #{f.path}")
      end
    end

    context 'when managing a present instance' do
      let(:manifest) { 'composite_namevar { php-gem: }' }

      it { expect(@stdout_str).to match %r{Current State: \{:package=>"php", :manager=>"gem", :ensure=>"present"\}} }
      it { expect(@status.exitstatus).to eq 0 }
    end

    context 'when managing an absent instance' do
      let(:manifest) { 'composite_namevar { php-wibble: ensure=>\'absent\' }' }

      it { expect(@stdout_str).to match %r{Composite_namevar\[php-wibble\]: Nothing to manage: no ensure and the resource doesn't exist} }
      it { expect(@status.exitstatus).to eq 0 }
    end

    context 'when creating a previously absent instance' do
      let(:manifest) { 'composite_namevar { php-wibble: ensure=>\'present\' }' }

      it { expect(@stdout_str).to match %r{Composite_namevar\[php-wibble\]/ensure: defined 'ensure' as 'present'} }
      it { expect(@status.exitstatus).to eq 2 }
    end

    context 'when removing a previously present instance' do
      let(:manifest) { 'composite_namevar { php-yum: ensure=>\'absent\' }' }

      it { expect(@stdout_str).to match %r{Composite_namevar\[php-yum\]/ensure: undefined 'ensure' from 'present'} }
      it { expect(@status.exitstatus).to eq 2 }
    end
    # rubocop:enable RSpec/InstanceVariable
  end
end
