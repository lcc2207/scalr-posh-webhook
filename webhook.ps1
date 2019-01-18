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
    $responseString = $(ShowRequestData $request)
    $response.StatusCode = $responseString[0]
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseString[1])
    $response.ContentLength64 = $buffer.Length
    $output = $response.OutputStream
    $output.Write($buffer,0,$buffer.Length)
    $output.Close()
    $listener.Stop()
  }
}

Function ShowRequestData($request)
{

if (! $request.HasEntityBody)
{
Write "No client data was sent with the request."
return 400
}

$body = $request.InputStream
$encoding = $request.ContentEncoding
$reader = new-object System.IO.StreamReader($body, $encoding)
$info = $reader.ReadToEnd() | ConvertFrom-JSON
$body.Close()
$reader.Close()

$job = start-job -FilePath "c:\webhook\test.ps1" -ArgumentList $info.data.SCALR_INTERNAL_IP, $info.data.SCALR_SERVER_HOSTNAME
sleep 2
if ((get-job $job.name).state -eq "Completed")
 {
    $status = 200
 } else {
    $status = 400
 }

 $jobout = receive-job $job.name
 $statarr = @($status,$jobout)
 return $statarr
}

SimpleListener("http://*:5000/")
