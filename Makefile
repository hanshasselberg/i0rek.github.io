default: zip
	aws s3 rm s3://hans.io --recursive --profile hans.io
	aws s3 cp _site/index.html s3://hans.io/index.html --profile hans.io --acl public-read --cache-control="public, must-revalidate, proxy-revalidate, max-age=0" --content-encoding gzip
	aws s3 sync _site/ s3://hans.io --profile hans.io --acl public-read --cache-control="max-age=60" --content-encoding gzip --exclude "index.html"

zip: build
	for f in `find _site -type f`; do gzip -9 $$f; mv $$f.gz $$f; done

build:
	jekyll build
