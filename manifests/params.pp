class perfsonar::params(
  $regular_testing_install_ensure = 'present',
  $regular_testing_ensure         = 'stopped',
  $regular_testing_enable         = false,
  $regular_testing_loglvl         = 'INFO',
  $regular_testing_logger         = 'Log::Dispatch::FileRotate',
  $regular_testing_logfile        = '/var/log/perfsonar/regular_testing.log',
  $regular_testing_snotify        = true,
  $mesh_config_install_ensure     = 'present',
  $mesh_config_agent              = {},
  $owamp_install_ensure           = 'present',
  $owamp_ensure                   = 'stopped',
  $owamp_enable                   = false,
  $bwctl_install_ensure           = 'present',
  $bwctl_ensure                   = 'stopped',
  $bwctl_enable                   = false,
  $esmond_dbname                  = 'esmond',
  $esmond_dbuser                  = 'esmond',
  $esmond_dbpass                  = 'jqIqSIiuzwI0FMUu',
) {
  # package list taken from centos6-netinstall.cfg (from the perfsonar netinstall cd)
  # system packages (already installed on standard installation) and
  # packages that are dependencies of packages in this list have been removed from the original list
  # general perfsonar packages
  $install_packages = [
    'perl-perfSONAR_PS-Toolkit',
    # installed as dependencies, but need them here to get the dependencies in puppet right
    'httpd',
    'esmond',
# don't want to install SystemEnvironment because it keeps overwriting my configurations during updates
#   'perl-perfSONAR_PS-Toolkit-SystemEnvironment',
# don't want to install gcc and mysql, it's not required
#   'gcc',
#   'mysql-devel',
# is this for the web100 kernel only ??
#    'kmod-sk98lin',
# are the ones below still required ?
#    'device-mapper-multipath',
#    'php-gd',
#    'php-xml',
#    'syslinux',
#    'xplot-tcptrace',
  ]
  # other packages in the original kickstart, but left out
  # 'perl-DBD-mysql' doesn't exist, it's called perl-DBD-MySQL
  # 'xkeyboard-config' do we need it, we don't run X ??
  # 'comps-extras' contains images only, do we need it ??

  $regular_testing_packages = [
    'perl-perfSONAR_PS-RegularTesting',
    'perl-DBD-MySQL', # required by regular testing ? I've seen related error message in the logs when it's not installed
  ]
  $mesh_config_packages = [
    'perl-perfSONAR_PS-MeshConfig-Agent',
  ]
  # we should split client and server at some point
  $owamp_packages = [
    'owamp-client',
    'owamp-server',
    'owamp', # this installs both, the client and the server, plus I2util (which is installed by neither the client nor the server)
  ]
  # we should split client and server at some point
  $bwctl_packages = [
    'bwctl-client',
    'bwctl-server',
    'bwctl', # this installs both, the client and the server
    'iperf3', # bwctl packages install iperf and iperf3-devel as dependency, but not iperf3 ???
  ]

  # apache default options
  $hostcert = '/etc/grid-security/hostcert.pem'
  $hostkey = '/etc/grid-security/hostkey.pem'
  $capath = '/etc/grid-security/certificates'
  $clientauth = 'optional'
  $verifydepth = '5'

  # service status defaults
  $config_daemon_ensure = 'running'
  $config_daemon_enable = true
  $config_nic_params = true
  $generate_motd_enable = false
  $htcacheclean_ensure = 'stopped'
  $htcacheclean_enable = false
  $httpd_ensure = 'running'
  $httpd_enable = true
  $ls_cache_daemon_ensure = 'running'
  $ls_cache_daemon_enable = true
  $ls_reg_daemon_ensure = 'running'
  $ls_reg_daemon_enable = true
  $multipathd_ensure = 'stopped'
  $multipathd_enable = false
  $ndt_ensure = 'stopped'
  $ndt_enable = false
  $npad_ensure = 'stopped'
  $npad_enable = false
  $nscd_ensure = 'stopped'
  $nscd_enable = false
  $ls_bs_client_ensure = 'stopped'
  $ls_bs_client_enable = false
  $cassandra_ensure = 'running'
  $cassandra_enable = true

  # default mesh config
  $agentconfig = {
    mesh => [],
    restart_services       => 0,
    use_toolkit            => 1,
    send_error_emails      => 1,
    skip_redundant_tests   => 1,
  }
  # paths
  case $::osfamily {
    'RedHat': {
      $httpd_package    = 'httpd'
      $httpd_service    = 'httpd'
      $httpd_hasrestart = true
      $httpd_hasstatus  = true
      $httpd_dir        = '/etc/httpd'
      $mod_dir          = "${httpd_dir}/conf.d"
      $conf_dir         = "${httpd_dir}/conf.d"
    }
    default: {
      fail("osfamily ${::osfamily} is not supported")
    }
  }
}