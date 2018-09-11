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
    ShowRequestData $request
    $cmdresponse = "ok"
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
Write "starting script"
Write $info.data.SCALR_EXTERNAL_IP
start-job -FilePath "c:\scripts\test.ps1"
}

SimpleListener("http://*:5000/")
