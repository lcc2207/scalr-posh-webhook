Function SimpleListener($prefixes)
{
  if ($prefixes -eq $null -or $prefixes.Length -eq 0)
    {
      throw "need prefixes"
    }

  $listener = new-object system.net.HttpListener

  foreach ($s in $prefixes)
    {
      $listener.Prefixes.Add($s)
    }

  while ($true)
  {
    $listener.Start()

    "Listening..."
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response
    $responseString = $(validate_request $request)
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseString)
    $response.ContentLength64 = $buffer.Length
    $output = $response.OutputStream
    $output.Write($buffer,0,$buffer.Length)
    $output.Close()
    $listener.Stop()
  }
}

Function validate_request($request)
{
  if (! $request.Headers["X-Signature"])
  {
    $cmdresponse = "403"
  }
  else
  {
    $cmdresponse = $(ShowRequestData $request)
  }

  return $cmdresponse
}

Function ShowRequestData($request)
{

if (! $request.HasEntityBody)
{
Write "No client data was sent with the request."
return
}

$body = $request.InputStream
$encoding = $request.ContentEncoding
$reader = new-object System.IO.StreamReader($body, $encoding)
$info = $reader.ReadToEnd() | ConvertFrom-JSON
Write $info
$body.Close()
$reader.Close()

$job = start-job -FilePath "c:\scripts\dns.ps1" -ArgumentList $info.data.SCALR_INTERNAL_IP, $info.data.SCALR_SERVER_HOSTNAME
if ((get-job $job.name).state -eq "Completed")
 {
    $status = 200
 } else {
    $status = 304
 }
 receive-job $job.name
 return $status
}

SimpleListener("http://*:5000/")
