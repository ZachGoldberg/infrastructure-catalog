# S3 Bucket With Seeded Object

Creates an S3 bucket and seeds a single object into it.

Defaults to writing `hello world` to `hello.txt`.

Secure-by-default: public access blocked, versioning enabled, SSE (AES256) enabled.

## Inputs

| Name | Description | Default |
|------|-------------|---------|
| `name` | Bucket name | (required) |
| `object_key` | Key of the seeded object | `hello.txt` |
| `object_content` | Content of the seeded object | `hello world` |
