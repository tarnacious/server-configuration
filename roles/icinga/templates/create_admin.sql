 /* openssl passwd -1 <password> */
INSERT INTO icingaweb_user (name, active, password_hash)
VALUES ('{{ icinga_web_user }}', 1, '{{ icinga_web_password }}')
ON DUPLICATE KEY UPDATE password_hash="{{ icinga_web_password }}"
