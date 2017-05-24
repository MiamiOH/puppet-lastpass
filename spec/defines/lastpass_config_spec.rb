require 'spec_helper'

describe 'lastpass::config', :type => :define do
  let(:title) { 'agent_disable' }

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(:environment => 'test', :puppet_vardir => '/var/lib/puppet')
      end

      context 'when not passing value' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_file('/var/lib/puppet/.lpass') }
        it { is_expected.not_to contain_file('/var/lib/puppet/.lpass/env') }
        it { is_expected.not_to contain_shellvar('lastpass-config-agent_disable') }
      end

      context 'when passing value with lowercase unprefixed title' do
        let(:title) { 'lowercase' }
        let(:params) { { :value => 1 } }
        it { is_expected.to contain_file('/var/lib/puppet/.lpass') }
        it { is_expected.to contain_file('/var/lib/puppet/.lpass/env') }
        it {
          is_expected.to contain_shellvar('lastpass-config-lowercase').with(
            :ensure   => 'present',
            :target   => '/var/lib/puppet/.lpass/env',
            :variable => 'LPASS_LOWERCASE',
            :value    => 1
          )
        }
      end

      context 'when passing value with uppercase prefixed title' do
        let(:title) { 'LPASS_UPPERCASE' }
        let(:params) { { :value => 1, :file => 'login' } }
        it { is_expected.to contain_file('/var/lib/puppet/.lpass') }
        it { is_expected.to contain_file('/var/lib/puppet/.lpass/login') }
        it {
          is_expected.to contain_shellvar('lastpass-config-LPASS_UPPERCASE').with(
            :ensure   => 'present',
            :target   => '/var/lib/puppet/.lpass/login',
            :variable => 'LPASS_UPPERCASE',
            :value    => 1
          )
        }
      end
    end
  end
end
