#!/bin/bash
#------------------------------------------------------------
#des: after install packages and modify configure file,
#     run it.
#------------------------------------------------------------

#--------keystone service----------
systemctl enable memcached
systemctl restart memcached

systemctl enable httpd
systemctl restart httpd


#-------glance service------
systemctl enable openstack-glance-api openstack-glance-registry
systemctl restart openstack-glance-api openstack-glance-registry
sleep 2

#-------nova service-------
systemctl enable openstack-nova-api.service openstack-nova-cert.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service

systemctl restart openstack-nova-api.service openstack-nova-cert.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
sleep 2

#-------neutron service------
systemctl enable neutron-server.service
systemctl restart neutron-server.service
sleep 2

#-------cinder service--------
systemctl enable openstack-cinder-api.service openstack-cinder-scheduler.service
systemctl restart openstack-cinder-api.service openstack-cinder-scheduler.service
sleep 2

#-------ceilometer service-----
systemctl enable openstack-ceilometer-api.service openstack-ceilometer-notification.service  openstack-ceilometer-central.service openstack-ceilometer-collector.service openstack-ceilometer-alarm-evaluator.service openstack-ceilometer-alarm-notifier.service

systemctl restart openstack-ceilometer-api.service openstack-ceilometer-notification.service  openstack-ceilometer-central.service openstack-ceilometer-collector.service openstack-ceilometer-alarm-evaluator.service openstack-ceilometer-alarm-notifier.service
sleep 2
