#!/usr/bin/php
<?php
# the url is read continously from standard input and 
# the output is the url download status

$proxyHost = null;
$proxyPort = null;
$waitSeconds = 3;

$workDir = ".";

$options = getopt("h:p:d:w:");

if(isset($options["h"])){
	$proxyHost = $options["h"];
}

if(isset($options["p"])){
	$proxyPort = $options["p"];
}

if(isset($options["d"])){
	$workDir = $options["d"];
}

if(isset($options["w"])){
	$waitSeconds = $options["w"];
}


# setup curl
$ch = curl_init();
curl_setopt($ch,CURLOPT_RETURNTRANSFER,true);
curl_setopt($ch,CURLOPT_FOLLOWLOCATION,true);	

# setup proxy if it is provided
if($proxyHost && $proxyPort){
	curl_setopt($ch, CURLOPT_PROXYTYPE, CURLPROXY_SOCKS5);
	curl_setopt($ch, CURLOPT_PROXY, "$proxyHost:$proxyPort");				
}

# switch working directory
chdir($workDir);


$fh = fopen("php://stdin","r");
while(($line = fgets($fh))){
	$line = trim($line);
	$parts = explode("\t", $line);
	$url = $parts[0];
	$errCnt = 0;

	if(count($parts) > 1){
		$status = $parts[1];
		if(preg_match("#DL_ERR(\d+)#", $status,$matches)){
			$errCnt = $matches[1];
		}		
	}

	# detect whether file exists
	$md5Name = md5($url) . ".htm";
	if(file_exists($md5Name)){
		error_log("WARN: file exists for $url");
		/// mark the status
		echo implode("\t", array($url,"DL_OK", "port:" . $proxyPort)) . "\n";		
		continue;
	}

	curl_setopt($ch, CURLOPT_URL, $url);
	/// download it
	$startTime = microtime();
	$content = curl_exec($ch);
	/// check the status
	$info = curl_getinfo($ch);
	$status = "DL_OK";
	if($info["http_code"] != 200){
		$errCnt++;
		$status = "DL_ERR" . $errCnt;
	} else{
		/// save the file 
		file_put_contents($md5Name, $content);
	}
	echo implode("\t", array($url,$status, "port:" . $proxyPort)) . "\n";
	
	$endTime = microtime();
	$sleepTime = $waitSeconds * 100000 - ($endTime - $startTime);
	if($sleepTime > 0){
		usleep($sleepTime);
	}
}


?>
