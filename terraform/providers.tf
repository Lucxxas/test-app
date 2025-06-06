terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "ASIASJFXSSZBI4BJAYC6"
  secret_key = "X1GDCRbxyfl8peH0FA6uzv1JyMIStbGXjTIYaOzh"
  token      = "IQoJb3JpZ2luX2VjEIf//////////wEaCXVzLXdlc3QtMiJHMEUCICbsqB1DaapJeD/v87mOLtZte2nkPrmpBry8FPhQ34yiAiEAzMSntbKnrO2r+fhydRd/hUr71EanDCwuPFudFogKANwqpAIIYBABGgwxNTcxNTEzMDMyMzQiDCUqxruFxRb4itvRtiqBAgUmXBiUSPL3YbYLOlxwm0FTGCvHUr04H+XCbEnuaGEeR+SYRqUkLchj7sUtFUdyChxFFFaiSJidijbO7Fahpqj/Qr6gyV0KuyaM57ys3U9JVjbzgQpAN/Vijg2Zdu9XlErPHqXsb/JvlQ63BJhCaD403Qw5SGHr0qG1rQNqZOy594W7uox3ketSaSYlqMAyp2xUmOS1Rq5D3akf1PAqAKfrSmJfBc7nk7DCKSfTnqP5wG7YNppj6i5R91OJmCTXCblA2yaYoMPGniGcCokAaV4cKeKd0wMl76VkVjjDdIqgIpQYq/F5o0t08v9iayCovIrNsDupZ+CR0Fa103zLfuM8MM72i8IGOp0B0I7fuyR5/sVY282/VbHFKZB1qGq/ePfbhoLgjIZdWhSHH29QM9Cbljzzf3whCnNDboiSou1+M/X93mkT+4+zM79fOQc/XjXkponhC3xN7Vx5jI2PJMAlPbUsGIf2QHjVQSZgLwvwfzbAnzbnHAkWtXjbhfD4sooabAbH6CcqasUrqPFL4XEeDCaTKuvx38BBP2mZVGKwmk5xizh6Wg=="
}
