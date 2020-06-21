import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class CertificateInfoPopup extends StatefulWidget {
  CertificateInfoPopup({Key key}) : super(key: key);

  @override
  _CertificateInfoPopupState createState() => _CertificateInfoPopupState();
}

class _CertificateInfoPopupState extends State<CertificateInfoPopup> {
  List<X509Certificate> _otherCertificates = [];
  X509Certificate _topMainCertificate;
  X509Certificate _selectedCertificate;
  
  @override
  Widget build(BuildContext context) {
    return _build();
  }
  
  Widget _build() {
    if (_topMainCertificate == null) {
      var webViewModel = Provider.of<WebViewModel>(context, listen: true);

      return FutureBuilder(
        future: webViewModel.webViewController.getCertificate(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.connectionState != ConnectionState.done) {
            return Container();
          }
          SslCertificate sslCertificate = snapshot.data;
          _topMainCertificate = sslCertificate.x509Certificate;
          _selectedCertificate = _topMainCertificate;

          return FutureBuilder(
            future: _getOtherCertificatesFromTopMain(_otherCertificates, _topMainCertificate),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return _buildCertificatesInfoAlertDialog();
              }
              return Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(
                      Radius.circular(2.5)
                    )
                  ),
                  padding: EdgeInsets.all(25.0),
                  width: 100.0,
                  height: 100.0,
                  child: CircularProgressIndicator(strokeWidth: 4.0,),
                ),
              );
            },
          );
        },
      );
    } else {
      return _buildCertificatesInfoAlertDialog();
    }
  }
  
  Future<void> _getOtherCertificatesFromTopMain(List<X509Certificate> otherCertificates, X509Certificate x509certificate) async {
    var authorityInfoAccess = x509certificate.authorityInfoAccess;
    if (authorityInfoAccess != null) {
      try {
        var caIssuerUrl = authorityInfoAccess[OID.caIssuers.toValue()];
        HttpClientRequest request = await HttpClient().getUrl(Uri.parse(caIssuerUrl));
        HttpClientResponse response = await request.close();
        var certData = await response.first;
        var cert = X509Certificate.fromData(data: certData);
        otherCertificates.add(cert);
        await _getOtherCertificatesFromTopMain(otherCertificates, cert);
      } catch (e) {}
    }

    var cRLDistributionPoints = x509certificate.cRLDistributionPoints;
    for (var i = 0; i < cRLDistributionPoints.length; i++) {
      var crlUrl = cRLDistributionPoints[i];
      try {
        HttpClientRequest request = await HttpClient().getUrl(Uri.parse(crlUrl));
        HttpClientResponse response = await request.close();
        var certData = await response.first;
        var cert = X509Certificate.fromData(data: certData);
        otherCertificates.add(cert);
        await _getOtherCertificatesFromTopMain(otherCertificates, cert);
      } catch (e) {}
    }
  }
  
  AlertDialog _buildCertificatesInfoAlertDialog() {
    var webViewModel = Provider.of<WebViewModel>(context, listen: true);
    var uri = Uri.parse(webViewModel.url);

    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.all(
                        Radius.circular(5.0)
                    )
                ),
                padding: EdgeInsets.all(5.0),
                child: Icon(Icons.lock, color: Colors.white, size: 20.0,),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(uri.host, style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),),
                      SizedBox(height: 15.0,),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text("Flutter Browser has verified that ${_topMainCertificate.issuer(dn: ASN1DistinguishedNames.COMMON_NAME)} has emitted the web site certificate.",
                              softWrap: true,
                              style: TextStyle(fontSize: 12.0),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15.0,),
                      RichText(
                        text: TextSpan(
                            text: "Certificate info",
                            style: TextStyle(color: Colors.blue, fontSize: 12.0),
                            recognizer: TapGestureRecognizer()..onTap = () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  List<X509Certificate> certificates = [_topMainCertificate];
                                  certificates.addAll(_otherCertificates);

                                  return AlertDialog(
                                    content: Container(
                                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width / 2.5),
                                        child: StatefulBuilder(
                                          builder: (context, setState) {
                                            List<DropdownMenuItem<X509Certificate>> dropdownMenuItems = [];
                                            certificates.forEach((certificate) {
                                              var name = _findCommonName(x509certificate: certificate, isSubject: true) ??
                                                  _findOrganizationName(x509certificate: certificate, isSubject: true) ?? "";
                                              if (name != "") {
                                                dropdownMenuItems.add(DropdownMenuItem<X509Certificate>(
                                                  value: certificate,
                                                  child: Text(name),
                                                ));
                                              }
                                            });

                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: <Widget>[
                                                Text("Certificate Viewer", style: TextStyle(fontSize: 24.0, color: Colors.black, fontWeight: FontWeight.bold),),
                                                SizedBox(height: 15.0,),
                                                DropdownButton<X509Certificate>(
                                                  isExpanded: true,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _selectedCertificate = value;
                                                    });
                                                  },
                                                  value: _selectedCertificate,
                                                  items: dropdownMenuItems,
                                                ),
                                                SizedBox(height: 15.0,),
                                                Flexible(
                                                  child: SingleChildScrollView(
                                                    child: _buildCertificateInfo(_selectedCertificate),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        )
                                    ),
                                  );
                                },
                              );
                            }
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCertificateInfo(X509Certificate x509certificate) {
    var issuedToSection = _buildIssuedToSection(x509certificate);
    var issuedBySection = _buildIssuedBySection(x509certificate);
    var validityPeriodSection = _buildValidityPeriodSection(x509certificate);
    var publicKeySection = _buildPublicKeySection(x509certificate);
    var fingerprintSection = _buildFingerprintSection(x509certificate);
    var extensionSection = _buildExtensionSection(x509certificate);

    var children = <Widget>[];
    children.addAll(issuedToSection);
    children.addAll(issuedBySection);
    children.addAll(validityPeriodSection);
    children.addAll(publicKeySection);
    children.addAll(fingerprintSection);
    children.addAll(extensionSection);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  String _findCountryName({@required X509Certificate x509certificate, @required bool isSubject}) {
    try {
      return (isSubject ?
      x509certificate.subject(dn: ASN1DistinguishedNames.COUNTRY_NAME) :
      x509certificate.issuer(dn: ASN1DistinguishedNames.COUNTRY_NAME)) ??
          x509certificate.block1.findOid(oid: OID.countryName).parent.sub.last.value;
    } catch(e) {}
    return null;
  }

  String _findStateOrProvinceName({@required X509Certificate x509certificate, @required bool isSubject}) {
    try {
      return (isSubject ?
      x509certificate.subject(dn: ASN1DistinguishedNames.STATE_OR_PROVINCE_NAME) :
      x509certificate.issuer(dn: ASN1DistinguishedNames.STATE_OR_PROVINCE_NAME)) ??
          x509certificate.block1.findOid(oid: OID.stateOrProvinceName).parent.sub.last.value;
    } catch(e) {}
    return null;
  }

  String _findCommonName({@required X509Certificate x509certificate, @required bool isSubject}) {
    try {
      return (isSubject ?
        x509certificate.subject(dn: ASN1DistinguishedNames.COMMON_NAME) :
        x509certificate.issuer(dn: ASN1DistinguishedNames.COMMON_NAME)) ??
        x509certificate.block1.findOid(oid: OID.commonName).parent.sub.last.value;
    } catch(e) {}
    return null;
  }

  String _findOrganizationName({@required X509Certificate x509certificate, @required bool isSubject}) {
    try {
      return (isSubject ?
        x509certificate.subject(dn: ASN1DistinguishedNames.ORGANIZATION_NAME) :
        x509certificate.issuer(dn: ASN1DistinguishedNames.ORGANIZATION_NAME)) ??
        x509certificate.block1.findOid(oid: OID.organizationName).parent.sub.last.value;
    } catch(e) {}
    return null;
  }

  String _findOrganizationUnitName({@required X509Certificate x509certificate, @required bool isSubject}) {
    try {
      return (isSubject ?
        x509certificate.subject(dn: ASN1DistinguishedNames.ORGANIZATIONAL_UNIT_NAME) :
        x509certificate.issuer(dn: ASN1DistinguishedNames.ORGANIZATIONAL_UNIT_NAME)) ??
        x509certificate.block1.findOid(oid: OID.organizationalUnitName).parent.sub.last.value;
    } catch(e) {}
    return null;
  }
  
  List<Widget> _buildIssuedToSection(X509Certificate x509certificate) {
    var subjectCountryName = _findCountryName(x509certificate: x509certificate, isSubject: true) ?? "<Not Part Of Certificate>";
    var subjectStateOrProvinceName = _findStateOrProvinceName(x509certificate: x509certificate, isSubject: true) ?? "<Not Part Of Certificate>";
    var subjectCN = _findCommonName(x509certificate: x509certificate, isSubject: true) ?? "<Not Part Of Certificate>";
    var subjectO = _findOrganizationName(x509certificate: x509certificate, isSubject: true) ?? "<Not Part Of Certificate>";
    var subjectU = _findOrganizationUnitName(x509certificate: x509certificate, isSubject: true) ?? "<Not Part Of Certificate>";
    
    return <Widget>[
      Text("ISSUED TO", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      SizedBox(height: 5.0,),
      Text("Common Name (CN)", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      Text(subjectCN, style: TextStyle(fontSize: 14.0),),
      SizedBox(height: 5.0,),
      Text("Organization (O)", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      Text(subjectO, style: TextStyle(fontSize: 14.0),),
      SizedBox(height: 5.0,),
      Text("Organizational Unit (U)", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      Text(subjectU, style: TextStyle(fontSize: 14.0),),
      SizedBox(height: 5.0,),
      Text("Country", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      Text(subjectCountryName, style: TextStyle(fontSize: 14.0),),
      SizedBox(height: 5.0,),
      Text("State/Province", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      Text(subjectStateOrProvinceName, style: TextStyle(fontSize: 14.0),),
    ];
  }
  
  List<Widget> _buildIssuedBySection(X509Certificate x509certificate) {
    var issuerCountryName = _findCountryName(x509certificate: x509certificate, isSubject: false) ?? "<Not Part Of Certificate>";
    var issuerStateOrProvinceName = _findStateOrProvinceName(x509certificate: x509certificate, isSubject: false) ?? "<Not Part Of Certificate>";
    var issuerCN = _findCommonName(x509certificate: x509certificate, isSubject: false) ?? "<Not Part Of Certificate>";
    var issuerO = _findOrganizationName(x509certificate: x509certificate, isSubject: false) ?? "<Not Part Of Certificate>";
    var issuerU = _findOrganizationUnitName(x509certificate: x509certificate, isSubject: false) ?? "<Not Part Of Certificate>";
    var serialNumber = x509certificate.serialNumber?.map((byte) {
      var hexValue = byte.toRadixString(16);
      if (byte == 0 || hexValue.length == 1) {
        hexValue = "0" + hexValue;
      }
      return hexValue.toUpperCase();
    })
        ?.toList()?.join(":") ?? "<Not Part Of Certificate>";
    var version = x509certificate.version?.toString() ?? "<Not Part Of Certificate>";
    var sigAlgName = x509certificate.sigAlgName ?? "<Not Part Of Certificate>";
    
    return <Widget>[
      SizedBox(height: 15.0,),
      Text("ISSUED BY", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      SizedBox(height: 5.0,),
      Text("Common Name (CN)", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      Text(issuerCN, style: TextStyle(fontSize: 14.0),),
      SizedBox(height: 5.0,),
      Text("Organization (O)", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      Text(issuerO, style: TextStyle(fontSize: 14.0),),SizedBox(height: 5.0,),
      Text("Organizational Unit (U)", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      Text(issuerU, style: TextStyle(fontSize: 14.0),),
      SizedBox(height: 5.0,),
      Text("Country", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      Text(issuerCountryName, style: TextStyle(fontSize: 14.0),),
      SizedBox(height: 5.0,),
      Text("State/Province", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      Text(issuerStateOrProvinceName, style: TextStyle(fontSize: 14.0),),
      SizedBox(height: 5.0,),
      Text("Serial Number", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      Text(serialNumber, style: TextStyle(fontSize: 14.0),),
      SizedBox(height: 5.0,),
      Text("Version", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      Text(version, style: TextStyle(fontSize: 14.0),),
      SizedBox(height: 5.0,),
      Text("Signature Algorithm", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      Text(sigAlgName, style: TextStyle(fontSize: 14.0),),
    ];
  }
  
  List<Widget> _buildValidityPeriodSection(X509Certificate x509certificate) {
    var issuedOnDate = x509certificate.notBefore != null ? DateFormat("dd MMM yyyy HH:mm:ss").format(x509certificate.notBefore) : "<Not Part Of Certificate>";
    var expiresOnDate = x509certificate.notAfter != null ? DateFormat("dd MMM yyyy HH:mm:ss").format(x509certificate.notAfter) : "<Not Part Of Certificate>";
    
    return <Widget>[
      SizedBox(height: 15.0,),
      Text("VALIDITY PERIOD", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      SizedBox(height: 5.0,),
      Text("Issued on date", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      Text(issuedOnDate, style: TextStyle(fontSize: 14.0),),
      SizedBox(height: 5.0,),
      Text("Expires on date", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      Text(expiresOnDate, style: TextStyle(fontSize: 14.0),),
    ];
  }
  
  List<Widget> _buildPublicKeySection(X509Certificate x509certificate) {
    var publicKey = x509certificate.publicKey;
    var publicKeyAlg = "<Not Part Of Certificate>";
    var publicKeyAlgParams = "<Not Part Of Certificate>";
    if (publicKey != null) {
      if (publicKey.algOid != null) {
        publicKeyAlg = OID.fromValue(publicKey.algOid).name() + " ( ${publicKey.algOid} )";
      }
      if (publicKey.algParams != null) {
        publicKeyAlgParams = OID.fromValue(publicKey.algParams).name() + " ( ${publicKey.algParams} )";
      }
    }
    
    return <Widget>[
      SizedBox(height: 15.0,),
      Text("PUBLIC KEY", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      SizedBox(height: 5.0,),
      Text("Algorithm", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      Text(publicKeyAlg, style: TextStyle(fontSize: 14.0),),
      SizedBox(height: 5.0,),
      Text("Parameters", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      Text(publicKeyAlgParams, style: TextStyle(fontSize: 14.0),),
    ];
  }
  
  List<Widget> _buildFingerprintSection(X509Certificate x509certificate) {
    return <Widget>[
      SizedBox(height: 15.0,),
      Text("FINGERPRINT", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      SizedBox(height: 5.0,),
      Text("Fingerprint SHA-256", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      FutureBuilder(
        future: sha256.bind(Stream.value(x509certificate.encoded)).first,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.connectionState != ConnectionState.done) {
            return Text("");
          }

          Digest digest = snapshot.data;
          return Text(digest.bytes.map((byte) {
            var hexValue = byte.toRadixString(16);
            if (byte == 0 || hexValue.length == 1) {
              hexValue = "0" + hexValue;
            }
            return hexValue.toUpperCase();
          })
              .toList().join(" "), style: TextStyle(fontSize: 14.0),);
        },
      ),
      SizedBox(height: 5.0,),
      Text("Fingerprint SHA-1", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      FutureBuilder(
        future: sha1.bind(Stream.value(x509certificate.encoded)).first,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.connectionState != ConnectionState.done) {
            return Text("");
          }

          Digest digest = snapshot.data;
          return Text(digest.bytes.map((byte) {
            var hexValue = byte.toRadixString(16);
            if (byte == 0 || hexValue.length == 1) {
              hexValue = "0" + hexValue;
            }
            return hexValue.toUpperCase();
          })
              .toList().join(" "), style: TextStyle(fontSize: 14.0),);
        },
      ),
    ];
  }

  List<Widget> _buildExtensionSection(X509Certificate x509certificate) {
    var extensionSection = <Widget>[
      SizedBox(height: 15.0,),
      Text("EXTENSIONS", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
    ];
    
    extensionSection.addAll(_buildKeyUsageSection(x509certificate));
    extensionSection.addAll(_buildBasicConstraints(x509certificate));
    extensionSection.addAll(_buildExtendedKeyUsage(x509certificate));
    extensionSection.addAll(_buildSubjectKeyIdentifier(x509certificate));
    extensionSection.addAll(_buildAuthorityKeyIdentifier(x509certificate));
    extensionSection.addAll(_buildCertificatePolicies(x509certificate));
    extensionSection.addAll(_buildCRLDistributionPoints(x509certificate));
    extensionSection.addAll(_buildAuthorityInfoAccess(x509certificate));
    extensionSection.addAll(_buildSubjectAlternativeNames(x509certificate));
    
    return extensionSection;
  }
  
  List<Widget> _buildKeyUsageSection(X509Certificate x509certificate) {
    var criticalExtensionOIDs = x509certificate.criticalExtensionOIDs;
    var keyUsage = x509certificate.keyUsage;
    
    var keyUsageSection = <Widget>[
      SizedBox(height: 15.0,),
      Text("Key Usage ( ${OID.keyUsage.toValue()} )", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
    ];
    
    var keyUsageIsCritical = criticalExtensionOIDs
        .firstWhere((oid) => oid == OID.keyUsage.toValue(), orElse: () => null) != null ? "YES" : "NO";
    
    if (keyUsage.length > 0) {
      for (var i = 0; i < keyUsage.length; i++) {
        if (keyUsage[i]) {
          keyUsageSection.addAll(<Widget>[
            SizedBox(height: 5.0,),
            RichText(
              text: TextSpan(
                  children: [
                    TextSpan(
                        text: "Critical ",
                        style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.black)
                    ),
                    TextSpan(
                        text: keyUsageIsCritical,
                        style: TextStyle(fontSize: 12.0, color: Colors.black)
                    )
                  ]
              ),
            ),
            RichText(
              text: TextSpan(
                  children: [
                    TextSpan(
                        text: "Usage ",
                        style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.black)
                    ),
                    TextSpan(
                        text: KeyUsage.fromIndex(i).name(),
                        style: TextStyle(fontSize: 12.0, color: Colors.black)
                    )
                  ]
              ),
            ),
          ]);
        }
      }
    } else {
      keyUsageSection.addAll(<Widget>[
        SizedBox(height: 5.0,),
        Text("<Not Part Of Certificate>", style: TextStyle(fontSize: 14.0),),
      ]);
    }
    
    return keyUsageSection;
  }

  List<Widget> _buildBasicConstraints(X509Certificate x509certificate) {
    var criticalExtensionOIDs = x509certificate.criticalExtensionOIDs;
    var basicConstraints = x509certificate.basicConstraints;

    var basicConstraintsSection = <Widget>[
      SizedBox(height: 15.0,),
      Text("Basic Constraints ( ${OID.basicConstraints.toValue()} )", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
    ];
    var basicConstraintsIsCritical = criticalExtensionOIDs.firstWhere((oid) => oid == OID.basicConstraints.toValue(), orElse: () => null) != null ? "YES" : "NO";
    if (basicConstraints == -1) {
      basicConstraintsSection.addAll(<Widget>[
        SizedBox(height: 5.0,),
        RichText(
          text: TextSpan(
              children: [
                TextSpan(
                    text: "Critical ",
                    style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.black)
                ),
                TextSpan(
                    text: basicConstraintsIsCritical,
                    style: TextStyle(fontSize: 12.0, color: Colors.black)
                )
              ]
          ),
        ),
        RichText(
          text: TextSpan(
              children: [
                TextSpan(
                    text: "Certificate Authority ",
                    style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.black)
                ),
                TextSpan(
                    text: "NO",
                    style: TextStyle(fontSize: 12.0, color: Colors.black)
                )
              ]
          ),
        ),
      ]);
    } else {
      basicConstraintsSection.addAll(<Widget>[
        SizedBox(height: 5.0,),
        RichText(
          text: TextSpan(
              children: [
                TextSpan(
                    text: "Critical ",
                    style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.black)
                ),
                TextSpan(
                    text: basicConstraintsIsCritical,
                    style: TextStyle(fontSize: 12.0, color: Colors.black)
                )
              ]
          ),
        ),
        RichText(
          text: TextSpan(
              children: [
                TextSpan(
                    text: "Certificate Authority ",
                    style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.black)
                ),
                TextSpan(
                    text: "YES",
                    style: TextStyle(fontSize: 12.0, color: Colors.black)
                )
              ]
          ),
        ),
        RichText(
          text: TextSpan(
              children: [
                TextSpan(
                    text: "Path Length Constraints ",
                    style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.black)
                ),
                TextSpan(
                    text: basicConstraints.toString(),
                    style: TextStyle(fontSize: 12.0, color: Colors.black)
                )
              ]
          ),
        ),
      ]);
    }
    
    return basicConstraintsSection;
  }
  
  List<Widget> _buildExtendedKeyUsage(X509Certificate x509certificate) {
    var criticalExtensionOIDs = x509certificate.criticalExtensionOIDs;
    var extendedKeyUsage = x509certificate.extendedKeyUsage;

    var extendedKeyUsageSection = <Widget>[
      SizedBox(height: 15.0,),
      Text("Extended Key Usage ( ${OID.extKeyUsage.toValue()} )", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
    ];
    var extendedKeyUsageIsCritical = criticalExtensionOIDs.firstWhere((oid) => oid == OID.extKeyUsage.toValue(), orElse: () => null) != null ? "YES" : "NO";
    if (extendedKeyUsage.length > 0) {
      for (var i = 0; i < extendedKeyUsage.length; i++) {
        OID oid = OID.fromValue(extendedKeyUsage[i]);

        extendedKeyUsageSection.addAll(<Widget>[
          SizedBox(height: 5.0,),
          RichText(
            text: TextSpan(
                children: [
                  TextSpan(
                      text: "Critical ",
                      style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.black)
                  ),
                  TextSpan(
                      text: extendedKeyUsageIsCritical,
                      style: TextStyle(fontSize: 12.0, color: Colors.black)
                  )
                ]
            ),
          ),
          RichText(
            text: TextSpan(
                children: [
                  TextSpan(
                      text: "Purpose #${i + 1} ",
                      style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.black)
                  ),
                  TextSpan(
                      text: "${oid.name()} ( ${oid.toValue()} )",
                      style: TextStyle(fontSize: 12.0, color: Colors.black)
                  )
                ]
            ),
          ),
        ]);
      }
    } else {
      extendedKeyUsageSection.addAll(<Widget>[
        SizedBox(height: 5.0,),
        Text("<Not Part Of Certificate>", style: TextStyle(fontSize: 14.0),),
      ]);
    }
    
    return extendedKeyUsageSection;
  }
  
  List<Widget> _buildSubjectKeyIdentifier(X509Certificate x509certificate) {
    var criticalExtensionOIDs = x509certificate.criticalExtensionOIDs;
    var subjectKeyIdentifier = x509certificate.subjectKeyIdentifier;

    var subjectKeyIdentifierSection = <Widget>[
      SizedBox(height: 15.0,),
      Text("Subject Key Identifier ( ${OID.subjectKeyIdentifier.toValue()} )", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
    ];
    var subjectKeyIdentifierIsCritical = criticalExtensionOIDs.firstWhere((oid) => oid == OID.subjectKeyIdentifier.toValue(), orElse: () => null) != null ? "YES" : "NO";
    if (subjectKeyIdentifier.length > 0) {

      var subjectKeyIdentifierToHexValue = subjectKeyIdentifier.map((byte) {
        var hexValue = byte.toRadixString(16);
        if (byte == 0 || hexValue.length == 1) {
          hexValue = "0" + hexValue;
        }
        return hexValue.toUpperCase();
      })
          .toList().join(" ");

      subjectKeyIdentifierSection.addAll(<Widget>[
        SizedBox(height: 5.0,),
        RichText(
          text: TextSpan(
              children: [
                TextSpan(
                    text: "Critical ",
                    style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.black)
                ),
                TextSpan(
                    text: subjectKeyIdentifierIsCritical,
                    style: TextStyle(fontSize: 12.0, color: Colors.black)
                )
              ]
          ),
        ),
        RichText(
          text: TextSpan(
              children: [
                TextSpan(
                    text: "Key ID ",
                    style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.black)
                ),
                TextSpan(
                    text: subjectKeyIdentifierToHexValue,
                    style: TextStyle(fontSize: 12.0, color: Colors.black)
                )
              ]
          ),
        )
      ]);
    } else {
      subjectKeyIdentifierSection.addAll(<Widget>[
        SizedBox(height: 5.0,),
        Text("<Not Part Of Certificate>", style: TextStyle(fontSize: 14.0),),
      ]);
    }
    
    return subjectKeyIdentifierSection;
  }
  
  List<Widget> _buildAuthorityKeyIdentifier(X509Certificate x509certificate) {
    var criticalExtensionOIDs = x509certificate.criticalExtensionOIDs;
    var authorityKeyIdentifier = x509certificate.authorityKeyIdentifier;

    var authorityKeyIdentifierSection = <Widget>[
      SizedBox(height: 15.0,),
      Text("Authority Key Identifier ( ${OID.authorityKeyIdentifier.toValue()} )", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
    ];
    var authorityKeyIdentifierIsCritical = criticalExtensionOIDs.firstWhere((oid) => oid == OID.authorityKeyIdentifier.toValue(), orElse: () => null) != null ? "YES" : "NO";
    if (authorityKeyIdentifier.length > 0) {

      var authorityKeyIdentifierToHexValue = authorityKeyIdentifier.map((byte) {
        var hexValue = byte.toRadixString(16);
        if (byte == 0 || hexValue.length == 1) {
          hexValue = "0" + hexValue;
        }
        return hexValue.toUpperCase();
      })
          .toList().join(" ");

      authorityKeyIdentifierSection.addAll(<Widget>[
        SizedBox(height: 5.0,),
        RichText(
          text: TextSpan(
              children: [
                TextSpan(
                    text: "Critical ",
                    style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.black)
                ),
                TextSpan(
                    text: authorityKeyIdentifierIsCritical,
                    style: TextStyle(fontSize: 12.0, color: Colors.black)
                )
              ]
          ),
        ),
        RichText(
          text: TextSpan(
              children: [
                TextSpan(
                    text: "Key ID ",
                    style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.black)
                ),
                TextSpan(
                    text: authorityKeyIdentifierToHexValue,
                    style: TextStyle(fontSize: 12.0, color: Colors.black)
                )
              ]
          ),
        )
      ]);
    } else {
      authorityKeyIdentifierSection.addAll(<Widget>[
        SizedBox(height: 5.0,),
        Text("<Not Part Of Certificate>", style: TextStyle(fontSize: 14.0),),
      ]);
    }
    
    return authorityKeyIdentifierSection;
  }

  List<Widget> _buildCertificatePolicies(X509Certificate x509certificate) {
    var criticalExtensionOIDs = x509certificate.criticalExtensionOIDs;
    var certificatePolicies = x509certificate.certificatePolicies;

    var certificatePoliciesIsCritical = criticalExtensionOIDs.firstWhere((oid) => oid == OID.extKeyUsage.toValue(), orElse: () => null) != null ? "YES" : "NO";

    var certificatePoliciesSection = <Widget>[
      SizedBox(height: 15.0,),
      Text("Certificate Policies ( ${OID.certificatePolicies.toValue()} )", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      SizedBox(height: 5.0,),
      RichText(
        text: TextSpan(
            children: [
              TextSpan(
                  text: "Critical ",
                  style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.black)
              ),
              TextSpan(
                  text: certificatePoliciesIsCritical,
                  style: TextStyle(fontSize: 12.0, color: Colors.black)
              )
            ]
        ),
      ),
    ];

    if (certificatePolicies.length > 0) {
      for (var i = 0; i < certificatePolicies.length; i++) {
        OID oid = OID.fromValue(certificatePolicies[i]);

        certificatePoliciesSection.addAll(<Widget>[
          RichText(
            text: TextSpan(
                children: [
                  TextSpan(
                      text: "ID policy num. ${i + 1} ",
                      style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.black)
                  ),
                  TextSpan(
                      text: (oid != null) ? "${oid.name()} ( ${oid.toValue()} )" : "( ${certificatePolicies[i]} )",
                      style: TextStyle(fontSize: 12.0, color: Colors.black)
                  )
                ]
            ),
          ),
        ]);
      }
    } else {
      certificatePoliciesSection.addAll(<Widget>[
        SizedBox(height: 5.0,),
        Text("<Not Part Of Certificate>", style: TextStyle(fontSize: 14.0),),
      ]);
    }

    return certificatePoliciesSection;
  }

  List<Widget> _buildCRLDistributionPoints(X509Certificate x509certificate) {
    var criticalExtensionOIDs = x509certificate.criticalExtensionOIDs;
    var cRLDistributionPoints = x509certificate.cRLDistributionPoints;

    var cRLDistributionPointsIsCritical = criticalExtensionOIDs
        .firstWhere((oid) => oid == OID.cRLDistributionPoints.toValue(), orElse: () => null) != null ? "YES" : "NO";

    var cRLDistributionPointsSection = <Widget>[
      SizedBox(height: 15.0,),
      Text("CRL Distribution Points ( ${OID.cRLDistributionPoints.toValue()} )", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      SizedBox(height: 5.0,),
      RichText(
        text: TextSpan(
            children: [
              TextSpan(
                  text: "Critical ",
                  style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.black)
              ),
              TextSpan(
                  text: cRLDistributionPointsIsCritical,
                  style: TextStyle(fontSize: 12.0, color: Colors.black)
              )
            ]
        ),
      ),
    ];

    if (cRLDistributionPoints.length > 0) {
      for (var i = 0; i < cRLDistributionPoints.length; i++) {
        cRLDistributionPointsSection.addAll(<Widget>[
          RichText(
            text: TextSpan(
                children: [
                  TextSpan(
                      text: "URI ",
                      style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.black)
                  ),
                  TextSpan(
                      text: cRLDistributionPoints[i],
                      style: TextStyle(fontSize: 12.0, color: Colors.blue),
                      recognizer: TapGestureRecognizer()..onTap = () async {
                        final taskId = await FlutterDownloader.enqueue(
                          url: cRLDistributionPoints[i],
                          savedDir: (await getExternalStorageDirectory()).path,
                          showNotification: true, // show download progress in status bar (for Android)
                          openFileFromNotification: true, // click on notification to open downloaded file (for Android)
                        );
                      }
                  )
                ]
            ),
          ),
        ]);
      }
    } else {
      cRLDistributionPointsSection.addAll(<Widget>[
        SizedBox(height: 5.0,),
        Text("<Not Part Of Certificate>", style: TextStyle(fontSize: 14.0),),
      ]);
    }

    return cRLDistributionPointsSection;
  }

  List<Widget> _buildAuthorityInfoAccess(X509Certificate x509certificate) {
    var criticalExtensionOIDs = x509certificate.criticalExtensionOIDs;
    var authorityInfoAccess = x509certificate.authorityInfoAccess;

    var authorityInfoAccessIsCritical = criticalExtensionOIDs
        .firstWhere((oid) => oid == OID.authorityInfoAccess.toValue(), orElse: () => null) != null ? "YES" : "NO";

    var authorityInfoAccessSection = <Widget>[
      SizedBox(height: 15.0,),
      Text("Authority Info Access ( ${OID.authorityInfoAccess.toValue()} )", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      SizedBox(height: 5.0,),
      RichText(
        text: TextSpan(
            children: [
              TextSpan(
                  text: "Critical ",
                  style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.black)
              ),
              TextSpan(
                  text: authorityInfoAccessIsCritical,
                  style: TextStyle(fontSize: 12.0, color: Colors.black)
              )
            ]
        ),
      ),
    ];

    if (authorityInfoAccess.isNotEmpty) {
      var keys = authorityInfoAccess.keys;
      for (var i = 0; i < keys.length; i++) {
        var key = keys.elementAt(i);
        var value = authorityInfoAccess[key];
        var oid = OID.fromValue(key);

        authorityInfoAccessSection.addAll(<Widget>[
          RichText(
            text: TextSpan(
                children: [
                  TextSpan(
                      text: "Method #${i + 1} ",
                      style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.black)
                  ),
                  TextSpan(
                    text: oid != null ? "${oid.name()} ( ${oid.toValue()} )" : key,
                    style: TextStyle(fontSize: 12.0, color: Colors.black),
                  )
                ]
            ),
          ),
          RichText(
            text: TextSpan(
                children: [
                  TextSpan(
                      text: "URI ",
                      style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.black)
                  ),
                  TextSpan(
                      text: value,
                      style: TextStyle(fontSize: 12.0, color: Colors.blue),
                      recognizer: TapGestureRecognizer()..onTap = () async {
                        final taskId = await FlutterDownloader.enqueue(
                          url: value,
                          savedDir: (await getExternalStorageDirectory()).path,
                          showNotification: true, // show download progress in status bar (for Android)
                          openFileFromNotification: true, // click on notification to open downloaded file (for Android)
                        );
                      }
                  )
                ]
            ),
          ),
        ]);
      }
    } else {
      authorityInfoAccessSection.addAll(<Widget>[
        SizedBox(height: 5.0,),
        Text("<Not Part Of Certificate>", style: TextStyle(fontSize: 14.0),),
      ]);
    }

    return authorityInfoAccessSection;
  }
  
  List<Widget> _buildSubjectAlternativeNames(X509Certificate x509certificate) {
    var criticalExtensionOIDs = x509certificate.criticalExtensionOIDs;
    var subjectAlternativeNames = x509certificate.subjectAlternativeNames;

    var subjectAlternativeNamesSection = <Widget>[
      SizedBox(height: 15.0,),
      Text("Subject Alternative Names ( ${OID.subjectAltName.toValue()} )", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
    ];
    var subjectAlternativeNamesIsCritical = criticalExtensionOIDs.firstWhere((oid) => oid == OID.subjectAltName.toValue(), orElse: () => null) != null ? "YES" : "NO";
    if (subjectAlternativeNames.length > 0) {
      subjectAlternativeNamesSection.addAll(<Widget>[
        SizedBox(height: 5.0,),
        RichText(
          text: TextSpan(
              children: [
                TextSpan(
                    text: "Critical ",
                    style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.black)
                ),
                TextSpan(
                    text: subjectAlternativeNamesIsCritical,
                    style: TextStyle(fontSize: 12.0, color: Colors.black)
                )
              ]
          ),
        ),
      ]);
      subjectAlternativeNames.forEach((subjectAlternativeName) {
        subjectAlternativeNamesSection.addAll(<Widget>[
          SizedBox(height: 5.0,),
          RichText(
            text: TextSpan(
                children: [
                  TextSpan(
                      text: "DNS Name ",
                      style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.black)
                  ),
                  TextSpan(
                      text: subjectAlternativeName,
                      style: TextStyle(fontSize: 12.0, color: Colors.black)
                  )
                ]
            ),
          ),
        ]);
      });
    } else {
      subjectAlternativeNamesSection.addAll(<Widget>[
        SizedBox(height: 5.0,),
        Text("<Not Part Of Certificate>", style: TextStyle(fontSize: 14.0),),
      ]);
    }
    
    return subjectAlternativeNamesSection;
  }
}