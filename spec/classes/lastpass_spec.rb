require 'spec_helper'

describe 'lastpass', :type => :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(:environment => 'test', :puppet_vardir => '/var/lib/puppet')
      end

      context 'with defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('lastpass-cli') }
        it { is_expected.to contain_file('/usr/local/bin/lpasspw') }
        it { is_expected.to contain_file('/usr/local/bin/lpasslogin') }
        it { is_expected.not_to contain_file('/var/lib/puppet/.lpass') }
        it { is_expected.not_to contain_file('/var/lib/puppet/.lpass/login') }
        it { is_expected.not_to contain_file('/var/lib/puppet/.lpass/env') }
        it { is_expected.not_to contain_lastpass__config('askpass') }
        it { is_expected.to contain_profiled__script('lpass.sh') }
      end

      context 'without manage_package' do
        let(:params) { { :manage_package => false } }
        it { is_expected.not_to contain_package('lastpass-cli') }
      end

      context 'with username' do
        let(:params) { { :username => 'lpassuser@example.com' } }
        it { is_expected.to contain_file('/var/lib/puppet/.lpass') }
        it { is_expected.to contain_file('/var/lib/puppet/.lpass/login') }
        it { is_expected.not_to contain_lastpass__config('askpass') }
      end

      context 'with password' do
        let(:params) { { :password => 'lpass_master_pw' } }
        it { is_expected.to contain_file('/var/lib/puppet/.lpass') }
        it { is_expected.to contain_file('/var/lib/puppet/.lpass/login') }
        it { is_expected.to contain_lastpass__config('askpass') }
      end

      context 'with config' do
        let(:params) { { :agent_timeout => 3600, :sync_type => 'auto' } }
        it { is_expected.to contain_file('/var/lib/puppet/.lpass') }
        it { is_expected.to contain_file('/var/lib/puppet/.lpass/env') }
        it { is_expected.to contain_lastpass__config('agent_timeout') }
      end
    end
  end
end
