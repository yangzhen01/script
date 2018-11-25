#--------keystone service----------
systemctl stop memcached
systemctl stop httpd
sleep 2

#-------glance service------
systemctl stop openstack-glance-api openstack-glance-registry
sleep 2

#-------nova service-------
systemctl stop openstack-nova-api.service openstack-nova-cert.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
sleep 2
#-------neutron service------
systemctl stop neutron-server.service
sleep 2
#-------cinder service--------
systemctl stop openstack-cinder-api.service openstack-cinder-scheduler.service
sleep 2
#-------ceilometer service-----
systemctl stop openstack-ceilometer-api.service openstack-ceilometer-notification.service  openstack-ceilometer-central.service openstack-ceilometer-collector.service openstack-ceilometer-alarm-evaluator.service openstack-ceilometer-alarm-notifier.service
sleep 2
