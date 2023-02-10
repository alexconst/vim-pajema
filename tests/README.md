# browser selection notes

As of 2023 the problem with the use of firefox is that the recovery.jsonlz4 can take several seconds until it gets updated with the list of open tabs.
Edit: ahemmm... actually I could have still kept with firefox because on my test I have this line `silent execute '!sleep 5s'`
Edit2: a few other things to keep in mind is that 1) the session file for chromium only exists while the browser is open and 2) vim is not async by default (unless you use plugins or launch external processes while appending the `&` character) and independently you need to press enter (because vim waits for such input before it can continue after it launches an external process)
Note: I've updated the plugin itself to launch the browser in the background (with `&`) since it makes more sense anyway



```vim
let g:vim_pajema_browser = '/usr/bin/chromium'
```
```bash
strings ~/.config/chromium/Default/Sessions/Session_* | grep -E '^file:///' | sort -u
```


```vim
let g:vim_pajema_browser = '/usr/bin/firefox'
```
```bash
apt-get install liblz4-tool lz4json
lz4jsoncat $HOME/.mozilla/firefox/*.default-esr/sessionstore-backups/recovery.jsonlz4 | jq '.' | less
```

