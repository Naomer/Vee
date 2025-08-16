$imageUrls = @{
    "jwst.jpg" = "https://images.unsplash.com/photo-1614728894747-a83421e2b9c9?q=80&w=1000"
    "artemis.jpg" = "https://images.unsplash.com/photo-1614728263952-84ea256f9679?q=80&w=1000"
    "perseverance.jpg" = "https://images.unsplash.com/photo-1614728894747-a83421e2b9c9?q=80&w=1000"
}

foreach ($image in $imageUrls.GetEnumerator()) {
    $outputPath = "assets/images/$($image.Key)"
    Invoke-WebRequest -Uri $image.Value -OutFile $outputPath
    Write-Host "Downloaded $($image.Key)"
} 