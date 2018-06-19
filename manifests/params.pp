class perfsonar::params(
  $regular_testing_install_ensure        = 'present',
  $regular_testing_ensure                = 'stopped',
  $regular_testing_enable                = false,
  $regular_testing_config                = '/etc/perfsonar/regulartesting.conf',
present $regular_testing_libpath               = '/var/lib/perfsonar/regulartesting',
  $regular_testing_loglvl                = 'INFO',
  $regular_testing_logger                = 'Log::Dispatch::FileRotate',
  $regular_testing_logfile               = '/var/log/perfsonar/regular_testing.log',
  $regular_testing_snotify               = true,
  $regular_testing_lr_order              = '02',
  $regular_testing_lr_options            = [ 'weekly', 'compress', 'rotate 50', 'missingok', 'notifempty',
    'postrotate', '  /sbin/service regular_testing restart > /dev/null 2>/dev/null || true', 'endscript' ],
  $owamp_install_ensure                  = 'present',
  $owamp_ensure                          = 'stopped',
  $owamp_enable                          = false,
  $bwctl_install_ensure                  = 'present',
  $bwctl_ensure                          = 'stopped',
  $bwctl_enable                          = false,
  $esmond_dbname                         = 'esmond',
  $esmond_dbuser                         = 'esmond',
  $esmond_dbpass                         = 'jqIqSIiuzwI0FMUu',
  $esmond_use_db_module                  = true,
  $esmond_root                           = '/usr/lib/esmond',
  $esmond_conf_path                      = '/etc/esmond',
  $ls_registration_daemon_install_ensure = 'present',
  $ls_registration_daemon_ensure         = 'running',
  $ls_registration_daemon_enable         = true,
  $ls_registration_daemon_loglvl         = 'INFO',
  $ls_registration_daemon_logger         = 'Log::Dispatch::FileRotate',
  $ls_registration_daemon_logfile        = '/var/log/perfsonar/ls_registration_daemon.log',
  $ls_registration_daemon_snotify        = true,
  $ls_registration_daemon_lr_order       = '03',
  $ls_registration_daemon_lr_options     = [ 'weekly', 'compress', 'rotate 50', 'missingok', 'notifempty',
    'postrotate', '  /sbin/service ls_registration_daemon restart > /dev/null 2>/dev/null || true', 'endscript' ],
  $ls_cache_daemon_install_ensure        = 'present',
  $ls_cache_daemon_ensure                = 'running',
  $ls_cache_daemon_enable                = true,
  $ls_cache_daemon_loglvl                = 'INFO',
  $ls_cache_daemon_logger                = 'Log::Dispatch::FileRotate',
  $ls_cache_daemon_logfile               = '/var/log/perfsonar/ls_cache_daemon.log',
  $ls_cache_daemon_snotify               = true,
  $ls_cache_daemon_lr_order              = '04',
  $ls_cache_daemon_lr_options            = [ 'weekly', 'compress', 'rotate 50', 'missingok', 'notifempty',
    'postrotate', '  /sbin/service ls_cache_daemon restart > /dev/null 2>/dev/null || true', 'endscript' ],
  $patchdir                              = '/usr/local/share/perfsonar_patches',
  $patchpackage                          = 'patch',
  $patchpackage_ensure                   = 'present',
  $psadmin_group                         = 'wheel',
  $psadmin_user                          = ''
) {
  # os specifics
  case $::osfamily {
    'RedHat': {
      $modssl_package   = 'mod_ssl'
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
  # package list taken from centos6-netinstall.cfg (from the perfsonar netinstall cd)
  # system packages (already installed on standard installation) and
  # packages that are dependencies of packages in this list have been removed from the original list
  # general perfsonar packages
  $install_packages = [
    'perfsonar-toolkit',
    # installed as dependencies, but need them here to get the dependencies in puppet right
    $httpd_package,
    'esmond',
    'ndt-server',
    'npad',
    'nscd',
    'cassandra20',
    $modssl_package,
# don't want to install perfsonar-toolkit-systemenv because it keeps overwriting my configurations during updates
#   'perfsonar-toolkit-systemenv',
#     packages that are installed by perfsonar-toolkit-systemenv:
#       perfsonar-toolkit-ntp
#         configures ntp server (replaces existing config)
#       perfsonar-toolkit-security
#         configures iptables
#       perfsonar-toolkit-service-watcher
#         monitors status of services: mysql, httpd, cassandra, owamp, bwctl, npad, ndt, regular_testing, ls_registration_daemon, ls_cache_daemon, config_daemon
#         according to /opt/perfsonar_ps/toolkit/lib/perfSONAR_PS/NPToolkit/Services/*.pm, the following services need regular restarts: OWAMP, RegularTesting
#       perfsonar-toolkit-sysctl
#         configures /etc/sysctl.conf (appends values)
# unfortunately, with ps 3.5.1.x the main perfsonar-toolkit depends on perfsonar-toolkit-systemenv
# perfsonar-toolkit is also not a meta package, it contains necessary files, so it has to be installed
# the easiest option to avoid the systemenv package is to create dummy rpm with the same name and a higher version number

# are the ones below still required ?
     'device-mapper-multipath',
  ]

  $regular_testing_packages = [
    'perfsonar-regulartesting',
    #'perl-DBD-MySQL', # required by regular testing ? I've seen related error message in the logs when it's not installed
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
    'iperf3', # bwctl packages install iperf and iperf3-devel as dependencies, but not iperf3 ???
  ]
  $ls_cache_daemon_packages = [
    'perfsonar-lscachedaemon',
  ]
  # logrotate
  $logrotate_cf = '/etc/logrotate.d/perfsonar'
  $lr_header_order = '01'

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

  # disable db after upgrade to perfsonar 4.0
  if $::perfsonar_version and versioncmp($::perfsonar_version, '4.0') >= 0 {
    $esmond_use_db_module_real = false
  } else {
    $esmond_use_db_module_real = true
  }

}
