<div align="center">
  <a href="https://github.com/mac-brand-spaces/msgraph-userinfo-cli">
    <img src="images/logo.png" alt="Logo" width="80" height="80">
  </a>

<h3 align="center">MSGraph Userinfo CLI</h3>

  <p align="center">
    A small cli tool to get user information from the Microsoft Graph API
    <br />
    <br />
    <a href="https://github.com/mac-brand-spaces/msgraph-userinfo-cli/issues/new?labels=bug&template=bug-report---.yml">Report Bug</a>
    ·
    <a href="https://github.com/mac-brand-spaces/msgraph-userinfo-cli/issues/new?labels=enhancement&template=feature-request---.yml">Request Feature</a>
  </p>
</div>

<!-- TABLE OF CONTENTS -->
## Table of Contents

- [Table of Contents](#table-of-contents)
- [About The Project](#about-the-project)
  - [Built With](#built-with)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)
- [Acknowledgments](#acknowledgments)

<!-- ABOUT THE PROJECT -->
## About The Project

This is a small cli tool to get user information from the Microsoft Graph API. It is written in Delphi.

### Built With

- [![Delphi][Delphi]][Delphi-url]

<!-- GETTING STARTED -->
## Getting Started

### Prerequisites

- Delphi 11 Alexandria
- [boss](https://github.com/HashLoad/boss) (Dependency Manager for Delphi)

### Installation

```sh
boss install --global mac-brand-spaces/msgraph-userinfo-cli
```

or just download the latest release from [here](https://github.com/mac-brand-spaces/msgraph-userinfo-cli/releases/latest)

<!-- USAGE EXAMPLES -->
## Usage

You have to set Environment Variables for the following:

```batch
SET TENANTID=<your Tenant id>
SET CLIENTID=<your client id>
SET REDIRECTPATH=<your redirect path; eg. /MyApp>
SET REDIRECTPORT=<the port in your redirecu uri>
```

Your redirect uri must be sth like `http://localhost` and so on.

<!-- ROADMAP -->
## Roadmap

See the [open issues](https://github.com/mac-brand-spaces/msgraph-userinfo-cli/issues) for a full list of proposed features (and known issues).

<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<!-- LICENSE -->
## License

Distributed under the MIT License. See [`LICENSE`](./LICENSE) for more information.

<!-- CONTACT -->
## Contact

mac. brand spaces - [dev@mac.de](mailto:dev@mac.de)

Project Link: [https://github.com/mac-brand-spaces/.template](https://github.com/mac-brand-spaces/.template)

<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

- [Marius Kehl](https://github.com/MeroFuruya)

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[Delphi]: https://img.shields.io/badge/Delphi-EE1F35?style=for-the-badge&logo=delphi&logoColor=white
[Delphi-url]: https://www.embarcadero.com/de/products/delphi
