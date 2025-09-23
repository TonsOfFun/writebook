---
title: Installing on Digital Ocean
---
# Installing on Digital Ocean

One of the best ways to host Writebook is to use a cloud provider like <a href="https://www.digitalocean.com" target="_blank">Digital Ocean</a>. It's inexpensive and relatively easy to set up if you have a little technical know-how.

**Once you've signed up for a Digital Ocean account**, just follow these steps to get set up. It should take less than 5 minutes.

1. Choose `Create > Droplets` from the menu in your default project and pick a plan to get the server set up.  ![DO-create.png](/u/do-create-G0VYYI.png)
Minimum requirements are 2GB RAM/1CPU. We recommend the following setup:  ![DO-plan.png](/u/do-plan-IZHiLO.png)

2. Next, create a password for connecting to the server.  ![DO-password.png](/u/do-password-AVWxbD.png)

3. Accept the rest of the defaults and hit "Create Droplet" at the bottom of the screen. It will take just a few minutes for your droplet to be created. Once it's ready, click it to expand. ![DO-droplet.png](/u/do-droplet-JAJscl.png)

4. Next, copy the `ipv4` address which we'll use to point your domain name to your new cloud server. ![DO-ip.png](/u/do-ip-dc4gQX.png)

5. Now head over to wherever your domain is managed. Some common registrars are <a href="https://www.godaddy.com" target="_blank">GoDaddy</a>, <a href="https://www.namecheap.com" target="_blank">namecheap</a> or <a href="https://www.squarespace.com" target="_blank">Squarespace</a>. Sign in and look for a link to manage your domain. You need to add an `A record` that points to the IP you copied above. It'll look something like this: ![DO-a-record.png](/u/do-a-record-TBoVla.png)

6. Next, head back over to your Digital Ocean Droplet and open the Console to connect to your server. ![DO-console.png](/u/do-console-bswkQF.png)

7. Finally, find the install command in the confirmation email we sent you and paste it into the command line: ![do-cli.png](/u/do-cli-QqIe5C.png)

8. You'll be asked which domain name you will be using. That needs to be the same as the A record you set up in your domain manager. Type it in and ONCE will handle the rest. A few minutes later you'll see something like this: ![installation.png](/u/installation-qJ6Wol.png)

9. You're done! Open the URL in your web browser and set up your Writebook account.
