#!/bin/bash

discovery(){
  # screenshot $1
  # cleanup $1
  cat ./$1/$foldername/responsive-$(date +"%Y-%m-%d").txt | sort -u | while read line; do
    sleep 1
    dirsearcher $line
    report $1 $line
    echo "$line report genareted"
    sleep 1
  done
}
discovery_2(){
  # screenshot $1
  # cleanup $1
  cat ./$1/$foldername/live.txt | sort -u | while read line; do
    sleep 1
    dirsearcher $line
    report $1 $line
    echo "$line report genareted"
    sleep 1
  done
}

cleanup(){
  cd ./$1/$foldername/screenshots/
  rename 's/_/-/g' -- *
  cd $path
}

hostalive(){
  cat ./$1/$foldername/$1.txt | sort -u | while read line; do
    if [ $(curl --write-out %{http_code} --silent --output /dev/null -m 5 $line) = 000 ]
    then
      echo "$line was unreachable"
      touch ./$1/$foldername/unreachable.html
      echo "<b>$line</b> was unreachable<br>" >> ./$1/$foldername/unreachable.html
    else
      echo "$line is up"
      echo $line >> ./$1/$foldername/responsive-$(date +"%Y-%m-%d").txt
    fi
  done
}

checkhost(){
  while read subdomain; do
  if host -t A "$subdomain" > /dev/null;
  then
    # If host is live, print it into
    # a file called "live.txt".
    echo "$subdomain" >> ./$1/$foldername/host_live.txt
  else
    echo "$subdomain was unreachable"
    touch ./$1/$foldername/unreachable.html
    echo "<b>$subdomain</b> was unreachable<br>" >> ./$1/$foldername/unreachable.html
  fi
  done < ./$1/$foldername/subdomain-list.txt
}

checkhttprobe(){
  cat ./$1/$foldername/host_live.txt | httprobe > ./$1/$foldername/live.txt
}

checkmeg(){
  ../meg/meg -d 10 -c 200 / ./$1/$foldername/live.txt
}

screenshot(){
    echo "taking a screenshot of $line"
    python ~/tools/webscreenshot/webscreenshot.py -o ./$1/$foldername/screenshots/ -i ./$1/$foldername/responsive-$(date +"%Y-%m-%d").txt --timeout=10 -m
}

recon(){
  echo "Enumerate all known domains using sublist3r..."
  python3 ../Sublist3r/sublist3r.py -d $1 -t 10 -v -o ./$1/$foldername/subdomain-list.txt

  checkhost $1
  checkhttprobe $1
  checkmeg $1
  # hostalive $1

  # curl -s https://certspotter.com/api/v0/certs\?domain\=$1 | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | sort -u | grep $1 >> ./$1/$foldername/$1.txt
  discovery_2 $1
  cat ./$1/$foldername/$1.txt | sort -u > ./$1/$foldername/$1.txt

}

dirsearcher(){
  echo "Recursively bruteforce directories..."
  python3 ../dirsearch/dirsearch.py -x 301,302,503 -e php,asp,aspx,jsp,html,zip,jar,sql,log,txt,js,sh -r -R 3 -u $line
}


report(){
  touch ./$1/$foldername/reports/$line.html
  echo "<title> report for $line </title>" >> ./$1/$foldername/reports/$line.html
  echo "<html>" >> ./$1/$foldername/reports/$line.html
  echo "<head>" >> ./$1/$foldername/reports/$line.html
  echo "<link rel=\"stylesheet\" href=\"https://fonts.googleapis.com/css?family=Mina\" rel=\"stylesheet\">" >> ./$1/$foldername/reports/$line.html
  echo "</head>" >> ./$1/$foldername/reports/$line.html
  echo "<body><meta charset=\"utf-8\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"> <link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css\"> <script src=\"https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js\"></script> <script src=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js\"></script></body>" >> ./$1/$foldername/reports/$line.html
  echo "<div class=\"jumbotron text-center\"><h1> Recon Report for <a/href=\"http://$line.com\">$line</a></h1>" >> ./$1/$foldername/reports/$line.html
  echo "<p> Generated by <a/href=\"https://github.com/nahamsec/lazyrecon\"> LazyRecon</a> on $(date) </p></div>" >> ./$1/$foldername/reports/$line.html


  echo "   <div clsas=\"row\">" >> ./$1/$foldername/reports/$line.html
  echo "     <div class=\"col-sm-6\">" >> ./$1/$foldername/reports/$line.html
  echo "     <div style=\"font-family: 'Mina', serif;\"><h2>Dirsearch</h2></div>" >> ./$1/$foldername/reports/$line.html
  echo "<pre>" >> ./$1/$foldername/reports/$line.html
  cat ~/tools/dirsearch/reports/$line/* | while read rline; do echo "$rline" >> ./$1/$foldername/reports/$line.html
  done
  echo "</pre>   </div>" >> ./$1/$foldername/reports/$line.html

  echo "     <div class=\"col-sm-6\">" >> ./$1/$foldername/reports/$line.html
  echo "<div style=\"font-family: 'Mina', serif;\"><h2>Screeshot</h2></div>" >> ./$1/$foldername/reports/$line.html
  echo "<pre>" >> ./$1/$foldername/reports/$line.html
  echo "Port 80                              Port 443" >> ./$1/$foldername/reports/$line.html
  echo "<img/src=\"../screenshots/http-$line-80.png\" style=\"max-width: 500px;\"> <img/src=\"../screenshots/https-$line-443.png\" style=\"max-width: 500px;\"> <br>" >> ./$1/$foldername/reports/$line.html
  echo "</pre>" >> ./$1/$foldername/reports/$line.html

  echo "<div style=\"font-family: 'Mina', serif;\"><h2>Dig Info</h2></div>" >> ./$1/$foldername/reports/$line.html
  echo "<pre>" >> ./$1/$foldername/reports/$line.html
  dig $line >> ./$1/$foldername/reports/$line.html
  echo "</pre>" >> ./$1/$foldername/reports/$line.html

  echo "<div style=\"font-family: 'Mina', serif;\"><h2>Host Info</h1></div>" >> ./$1/$foldername/reports/$line.html
  echo "<pre>" >> ./$1/$foldername/reports/$line.html
  host $line >> ./$1/$foldername/reports/$line.html
  echo "</pre>" >> ./$1/$foldername/reports/$line.html

  echo "<div style=\"font-family: 'Mina', serif;\"><h2>Response Header</h1></div>" >> ./$1/$foldername/reports/$line.html
  echo "<pre>" >> ./$1/$foldername/reports/$line.html
  curl -sSL -D - $line  -o /dev/null >> ./$1/$foldername/reports/$line.html
  echo "</pre>" >> ./$1/$foldername/reports/$line.html

  echo "<div style=\"font-family: 'Mina', serif;\"><h1>Nmap Results</h1></div>" >> ./$1/$foldername/reports/$line.html
  echo "<pre>" >> ./$1/$foldername/reports/$line.html
  echo "nmap -sV -T3 -Pn -p3868,3366,8443,8080,9443,9091,3000,8000,5900,8081,6000,10000,8181,3306,5000,4000,8888,5432,15672,9999,161,4044,7077,4040,9000,8089,443,7447,7080,8880,8983,5673,7443" >> ./$1/$foldername/reports/$line.html
  nmap -sV -T3 -Pn -p3868,3366,8443,8080,9443,9091,3000,8000,5900,8081,6000,10000,8181,3306,5000,4000,8888,5432,15672,9999,161,4044,7077,4040,9000,8089,443,7447,7080,8880,8983,5673,7443 $line >> ./$1/$foldername/reports/$line.html
  echo "</pre></div>" >> ./$1/$foldername/reports/$line.html


  echo "</html>" >> ./$1/$foldername/reports/$line.html

}

# Use colors, but only if connected to a terminal, and that terminal
# supports them.
if [ -t 1 ]; then
  RB_RED=$(printf '\033[38;5;196m')
  RB_ORANGE=$(printf '\033[38;5;202m')
  RB_YELLOW=$(printf '\033[38;5;226m')
  RB_GREEN=$(printf '\033[38;5;082m')
  RB_BLUE=$(printf '\033[38;5;021m')
  RB_INDIGO=$(printf '\033[38;5;093m')
  RB_VIOLET=$(printf '\033[38;5;163m')

  RED=$(printf '\033[31m')
  GREEN=$(printf '\033[32m')
  YELLOW=$(printf '\033[33m')
  BLUE=$(printf '\033[34m')
  BOLD=$(printf '\033[1m')
  RESET=$(printf '\033[m')
else
  RB_RED=""
  RB_ORANGE=""
  RB_YELLOW=""
  RB_GREEN=""
  RB_BLUE=""
  RB_INDIGO=""
  RB_VIOLET=""

  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  BOLD=""
  RESET=""
fi

logo(){
  printf "${BLUE}%s\n" "reconnaissance starting up!"
  printf '  %s _%s        %s    %s      %s     %s   %s     %s     %s \n' $RB_RED $RB_ORANGE $RB_YELLOW $RB_GREEN $RB_RED $RB_BLUE $RB_INDIGO $RB_VIOLET $RB_RESET
  printf '  %s| |%s __ _ %s____%s _   _ %s_ __ %s___%s  ___ %s ___%s  _ __%s\n' $RB_RED $RB_ORANGE $RB_YELLOW $RB_GREEN $RB_RED $RB_BLUE $RB_INDIGO $RB_VIOLET $RB_RESET
  printf '  %s| |%s/ _  |%s_  /%s| | | %s|  __%s/ _ \%s/ __|%s/ _ \%s|  _ \ %s\n' $RB_RED $RB_ORANGE $RB_YELLOW $RB_GREEN $RB_RED $RB_BLUE $RB_INDIGO $RB_VIOLET $RB_RESET
  printf '  %s| |%s (_|  %s/ / %s| | | %s| | %s|  __/%s (__ %s (_) %s| | | %s\n' $RB_RED $RB_ORANGE $RB_YELLOW $RB_GREEN $RB_RED $RB_BLUE $RB_INDIGO $RB_VIOLET $RB_RESET
  printf '  %s|_|%s\__ _|%s___/%s \__  %s|_ %s  \___|%s\___|%s\___/%s|_| |_ %s\n' $RB_RED $RB_ORANGE $RB_YELLOW $RB_GREEN $RB_RED $RB_BLUE $RB_INDIGO $RB_VIOLET $RB_RESET
  printf '  %s   %s      %s    %s |___/%s    %s       %s     %s     %s       %s\n' $RB_RED $RB_ORANGE $RB_YELLOW $RB_GREEN $RB_RED $RB_BLUE $RB_INDIGO $RB_VIOLET $RB_RESET
  printf "\n"
  printf "${BLUE}%s\n" "nahamsec/lazyrecon v1.0 forked by storenth/lazyrecon v2.0"
  printf "${BLUE}${BOLD}%s${RESET}\n" "To keep up on the latest news and updates, follow me on Twitter: https://twitter.com/storenth"
  printf "${BLUE}${BOLD}%s${RESET}\n" "I am looking for your support: https://github.com/storenth/lazyrecon"

}

main(){
  clear
  logo

  if [ -d "./$1" ]
  then
    echo "This is a known target."
  else
    mkdir ./$1
  fi
  mkdir ./$1/$foldername
  mkdir ./$1/$foldername/reports/
  mkdir ./$1/$foldername/screenshots/
  touch ./$1/$foldername/unreachable.html
  # touch ./$1/$foldername/subdomain-list.txt
  # touch ./$1/$foldername/host_live.txt
  # touch ./$1/$foldername/live.txt


  touch ./$1/$foldername/responsive-$(date +"%Y-%m-%d").txt

    recon $1
}
logo
if [[ -z $@ ]]; then
  echo "Error: no targets specified."
  echo "Usage: ./lazyrecon.sh <target>"
  exit 1
fi

path=$(pwd)
foldername=recon-$(date +"%Y-%m-%d")
main $1