exec 3<>/dev/tcp/localhost/80
echo -e "GET / HTTP/1.0\r\nHost: localhost\r\n\r\n" >&3
cat <&3