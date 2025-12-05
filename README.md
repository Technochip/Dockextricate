This is typical dockerscript only with 150 lines of code
If you are already shell inside an container u cna use it to look out for privilage escalation using this

to copy and paste the script inside the container u can use this command directly :

cat << 'EOF' > test.sh
>
>
EOF

like this

![Running image](https://raw.githubusercontent.com/Technochip/Dockextricate/main/images/Running.png)

then do "chmod +x test.sh" and  directly run it inside which will give you output like

![Output image](https://raw.githubusercontent.com/Technochip/Dockextricate/main/images/output.png)

It dosent download any extra packages instead it utilises all default utilites for images like ubuntu and alpine.

It is not very detailed but the output can be useful for more investigation


THIS IS ONLY A SIMPLE SCRIPT THAT CAN BE DIRECTLY COPY PASTED TO RUN DIRECTLY 

``` DISCLAIMER: EDUCATIONAL PURPOSE ONLY !! ```
