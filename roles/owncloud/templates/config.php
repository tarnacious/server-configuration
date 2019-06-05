<?php
$CONFIG = array (
  'apps_paths' => [
    [
      'path' => OC::$SERVERROOT.'/apps',
      'url' => '/apps',
      'writable' => false,
    ],
    [
      'path' => OC::$SERVERROOT.'/apps-external',
      'url' => '/apps-external',
      'writable' => true,
    ],
  ],
  'updatechecker' => false,
  'instanceid' => '{{ owncloud_instance_id }}',
  'passwordsalt' => '{{ owncloud_password_salt }}',
  'secret' => '{{ owncloud_secret }}',
  'trusted_domains' =>
  array (
    0 => 'owncloud.tarnbarford.net',
  ),
  'datadirectory' => '/var/www/owncloud/data',
  'overwrite.cli.url' => 'https://owncloud.tarnbarford.net',
  'dbtype' => 'mysql',
  'version' => '10.1.1.1',
  'dbname' => 'owncloud',
  'dbhost' => 'localhost',
  'dbtableprefix' => 'oc_',
  'mysql.utf8mb4' => true,
  'dbuser' => '{{ owncloud_db_user }}',
  'dbpassword' => '{{ owncloud_db_password }}',
  'logtimezone' => 'UTC',
  'installed' => true,
  'memcache.local' => '\OC\Memcache\Redis',
  'redis' => [
      'host' => 'localhost',
      'port' => 6379,
      'timeout' => 0,
  ],
  'memcache.locking' => '\OC\Memcache\Redis', // Add this for best performance
  'mail_domain' => 'tarnbarford.net',
  'mail_from_address' => 'owncloud',
  'mail_smtpmode' => 'smtp',
  'mail_smtpauth' => 1,
  'mail_smtphost' => 'mail.tarnbarford.net',
  'mail_smtpport' => '587',
  'mail_smtpname' => '{{ owncloud_smtp_user }}',
  'mail_smtppassword' => '{{ owncloud_smtp_password }}',
  'mail_smtpsecure' => 'tls',
);
