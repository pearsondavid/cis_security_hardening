# frozen_string_literal: true

require 'spec_helper'

enforce_options = [true, false]

describe 'cis_security_hardening::rules::selinux_state' do
  on_supported_os.each do |os, os_facts|
    enforce_options.each do |enforce|
      context "on #{os}" do
        let(:pre_condition) do
          <<-EOF
          reboot { 'after_run':
            timeout => 60,
            message => 'forced reboot by Puppet',
            apply   => 'finished',
          }
          EOF
        end
        let(:facts) { os_facts }
        let(:params) do
          {
            'enforce' => enforce,
            'state' => 'enforcing',
          }
        end

        it {
          is_expected.to compile

          if enforce
            is_expected.to contain_file('/etc/selinux/config')
              .with(
                'ensure' => 'present',
                'owner'  => 'root',
                'group'  => 'root',
                'mode'   => '0644',
              )
              .that_notifies('Reboot[after_run]')

            is_expected.to contain_file_line('selinux_enforce')
              .with(
                'path'     => '/etc/selinux/config',
                'line'     => 'SELINUX=enforcing',
                'match'    => 'SELINUX=',
                'multiple' => true,
              )
              .that_notifies('Reboot[after_run]')
          else
            is_expected.not_to contain_file('/etc/selinux/config')
            is_expected.not_to contain_file_line('selinux_enforce')
          end
        }
      end
    end
  end
end