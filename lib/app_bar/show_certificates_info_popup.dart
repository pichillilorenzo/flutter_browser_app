import 'dart:developer';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ShowCertificateInfoPopup extends StatefulWidget {
  ShowCertificateInfoPopup({Key key}) : super(key: key);

  @override
  _ShowCertificateInfoPopupState createState() => _ShowCertificateInfoPopupState();
}

class _ShowCertificateInfoPopupState extends State<ShowCertificateInfoPopup> {
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
    var caIssuerUrl = x509certificate.block1.findOid(oid: OID.caIssuers)?.parent?.subAtIndex(1)?.value ?? null;
    if (caIssuerUrl != null) {
      try {
        HttpClientRequest request = await HttpClient().getUrl(Uri.parse(caIssuerUrl));
        HttpClientResponse response = await request.close();
        var certData = await response.first;
        var cert = X509Certificate.fromData(data: certData);
        otherCertificates.add(cert);
        await _getOtherCertificatesFromTopMain(otherCertificates, cert);
      } catch (e) {}
    }
    try {
      var crlUrl = x509certificate.block1.findOid(oid: OID.cRLDistributionPoints)?.parent?.subAtIndex(1)?.sub?.first?.sub?.first?.sub?.first?.sub?.first?.sub?.first?.value;
      HttpClientRequest request = await HttpClient().getUrl(Uri.parse(crlUrl));
      HttpClientResponse response = await request.close();
      var certData = await response.first;
      var cert = X509Certificate.fromData(data: certData);
      otherCertificates.add(cert);
      await _getOtherCertificatesFromTopMain(otherCertificates, cert);
    } catch (e) {}
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
                                        constraints: BoxConstraints(maxWidth: 250.0),
                                        child: StatefulBuilder(
                                          builder: (context, setState) {
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
                                                  items: certificates.map((certificate) {
                                                    var name = _findCommonName(x509certificate: certificate, isSubject: true) ?? "";
                                                    return DropdownMenuItem<X509Certificate>(
                                                      value: certificate,
                                                      child: Text(name),
                                                    );
                                                  }).toList(),
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
    var subjectCountryName = _findCountryName(x509certificate: x509certificate, isSubject: true) ?? "<Not Part Of Certificate>";
    var subjectStateOrProvinceName = _findStateOrProvinceName(x509certificate: x509certificate, isSubject: true) ?? "<Not Part Of Certificate>";
    var subjectCN = _findCommonName(x509certificate: x509certificate, isSubject: true) ?? "<Not Part Of Certificate>";
    var subjectO = _findOrganizationName(x509certificate: x509certificate, isSubject: true) ?? "<Not Part Of Certificate>";
    var subjectU = _findOrganizationUnitName(x509certificate: x509certificate, isSubject: true) ?? "<Not Part Of Certificate>";

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
    
    var issuedOnDate = x509certificate.notBefore != null ? DateFormat("dd MMM yyyy HH:mm:ss").format(x509certificate.notBefore) : "<Not Part Of Certificate>";
    var expiresOnDate = x509certificate.notAfter != null ? DateFormat("dd MMM yyyy HH:mm:ss").format(x509certificate.notAfter) : "<Not Part Of Certificate>";

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

    var subjectAlternativeNames = x509certificate.subjectAlternativeNames;

    var issuedToSection = <Widget>[
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

    var issuedBySection = <Widget>[
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

    var validityPeriodSection = <Widget>[
      SizedBox(height: 15.0,),
      Text("VALIDITY PERIOD", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      SizedBox(height: 5.0,),
      Text("Issued on date", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      Text(issuedOnDate, style: TextStyle(fontSize: 14.0),),
      SizedBox(height: 5.0,),
      Text("Expires on date", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      Text(expiresOnDate, style: TextStyle(fontSize: 14.0),),
    ];

    var publickKeySection = <Widget>[
      SizedBox(height: 15.0,),
      Text("PUBLIC KEY", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      SizedBox(height: 5.0,),
      Text("Algorithm", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      Text(publicKeyAlg, style: TextStyle(fontSize: 14.0),),
      SizedBox(height: 5.0,),
      Text("Parameters", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
      Text(publicKeyAlgParams, style: TextStyle(fontSize: 14.0),),
    ];

    var fingerprintSection = <Widget>[
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

    var extensionSection = <Widget>[
      SizedBox(height: 15.0,),
      Text("EXTENSIONS", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
    ];

    var subjectAlternativeNamesSection = <Widget>[
      SizedBox(height: 15.0,),
      Text("Subject Alternative Names", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
    ];
    if (subjectAlternativeNames.length > 0) {
      subjectAlternativeNames.forEach((subjectAlternativeName) {
        subjectAlternativeNamesSection.addAll(<Widget>[
          SizedBox(height: 5.0,),
          Text(subjectAlternativeName, style: TextStyle(fontSize: 14.0),),
        ]);
      });
    } else {
      subjectAlternativeNamesSection.addAll(<Widget>[
        SizedBox(height: 5.0,),
        Text("<Not Part Of Certificate>", style: TextStyle(fontSize: 14.0),),
      ]);
    }
    extensionSection.addAll(subjectAlternativeNamesSection);

    var children = <Widget>[];
    children.addAll(issuedToSection);
    children.addAll(issuedBySection);
    children.addAll(validityPeriodSection);
    children.addAll(publickKeySection);
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
}