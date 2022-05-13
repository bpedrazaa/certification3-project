resource "aws_s3_bucket" "prod_website" {  
    bucket = "factory-bucket-frontend"
    
    tags = {
        Name = "factory-bucket"
    }
}

resource "aws_s3_bucket_acl" "prod_website_acl" {
  bucket = aws_s3_bucket.prod_website.id   
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "prod_website_conf" {
  bucket = aws_s3_bucket.prod_website.id   

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "prod_website_policy" {  
    bucket = aws_s3_bucket.prod_website.id   
    policy = <<POLICY
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "AddPermissions",
                "Effect": "Allow",
                "Principal": "*",
                "Action": "s3:GetObject",
                "Resource": "arn:aws:s3:::${aws_s3_bucket.prod_website.id}/*"
            }
        ]
    }
    POLICY
}

resource "aws_s3_object" "upload_asset_m" {
    bucket = aws_s3_bucket.prod_website.id   
    key = "asset-manifest.json"
    source = "build/asset-manifest.json"
}

resource "aws_s3_object" "upload_manifest" {
    bucket = aws_s3_bucket.prod_website.id   
    key = "manifest.json"
    source = "build/manifest.json"
}

resource "aws_s3_object" "upload_index" {
    bucket = aws_s3_bucket.prod_website.id   
    key = "index.html"
    content_type = "text/html"
    source = "build/index.html"
}

resource "aws_s3_object" "upload_static" {
    bucket = aws_s3_bucket.prod_website.id
    for_each = fileset("build/static/", "*")
    key = each.value
    source = "build/static/${each.value}"
}