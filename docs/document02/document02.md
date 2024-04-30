# Document01 - Enable HTTPS

[Back](../../README.md)

- [Document01 - Enable HTTPS](#document01---enable-https)
  - [Enable HTTPS using ACM](#enable-https-using-acm)
  - [Debug CSRF verification failed](#debug-csrf-verification-failed)
  - [Test HTTPS](#test-https)

---

## Enable HTTPS using ACM

- Create a certificate in ACM

![doc01](./pic/doc31.png)

- Create target group

![doc01](./pic/doc30.png)

- Create Application load balancer

![doc01](./pic/doc32.png)

Add 2 listeners

![doc01](./pic/doc33.png)

Select certificate from ACM

![doc01](./pic/doc34.png)

- Update DNS record in Route53

![doc01](./pic/doc35.png)

---

## Debug CSRF verification failed

- Add parameter into settings.py

```py
CSRF_TRUSTED_ORIGINS = ["http://*.arguswatcher.net", "https://*.arguswatcher.net"]
```

![doc01](./pic/doc36.png)

## Test HTTPS

So far, the DjangoBlog application is deployed on EC2 with HTTPS protocol.

![doc01](./pic/doc37.png)

![doc01](./pic/doc38.png)

---

[Top](#document01---enable-https)
