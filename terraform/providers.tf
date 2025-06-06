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
  access_key = "ASIASJFXSSZBP7FQSLFQ"
  secret_key = "CVz3G2oxLCSlgmqoIOUiSVInDTBj3Gw3Onm884ea"
  token      = "IQoJb3JpZ2luX2VjEIP//////////wEaCXVzLXdlc3QtMiJHMEUCIQDM10mHvlbTcfHkiDF2KvWbs86wL0zQUFF9cXfIHn6aCwIgM3te/SASAKQ0uF/fflYtu51ahyzDhpn0qdjrZjf5N5AqpAIIXBABGgwxNTcxNTEzMDMyMzQiDGuiiGamuanAtW/gACqBAlRkrZrLSeMie1nM3QSmAOviBWFkUVScSEjB7lL3MJF4fWJ2DWieT9K4GTHE5Qc4yh7ZToz95V8ts3PZheCWE6LMSkXFmGwKiLY4gXBu8D4PAacti7m2hXJ02xb0TiUPlV37vw4/fBxLYnpC0yJOknYPD1R2xgGQtb+NmHI/RzA2qbjv2t7scAUH7Ms+npzBLDZq18XMco3m59FqUM3htVTiktSk+yLezCfkyfx03acKdFqwJG3Z0IzyxU6x6LOoDooP8Ll0WeXTMYl/39EjZwk3EDOusQrmNYjh9kV1rw6s2B6gfckWfKpV/AGcgP5t1h48aAmSAwIPacRseOFqvE+9MOaEi8IGOp0B40b/jkiyY53my0Pd3Hyl2qP1qI3PpeQ8SOvco3bKjJ+aD2Mb8/1kXO6ITv4Hu5yJ/LrK9rAcle50d+AxGGIT0B5TewWOkge8PBN6d3FOx3nFYrKKpgSlOzrHprQK/KW9ha4FG5ESvgSj2249v6Ug6/Gf4F0K7ov+1aSMZ3evmb6Zag9/lPMWkFD1H90gbbnT2xpLb/tDJPhsi2Ih0Q=="
}
