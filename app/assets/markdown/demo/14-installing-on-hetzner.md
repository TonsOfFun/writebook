---
title: Installing on Hetzner
---
# Installing on Hetzner

One of the best ways to host Writebook is to use a cloud provider like <a href="https://www.hetzner.com" target="_blank">Hetzner</a>. It's inexpensive and relatively easy to set up if you have a little technical know-how.

**Once you've signed up for a Hetzner account**, just follow these steps to get set up. It should take less than 5 minutes.

1. Choose `+ Create Server` in your default project and pick a plan to get the server set up.     ![hz-dash.png](/u/hz-dash-MUZN1e.png)
Minimum requirements are 2GB RAM/1CPU. We recommend the following setup:   ![hz-plan.png](/u/hz-plan-57QAVM.png)

3. Accept the rest of the defaults and hit `Create and Buy now` at the bottom of the screen. It will take just a few minutes for your server to be created.

4. Once it's ready, copy the `Public IP` address which we'll use to point your domain name to your new cloud server.   ![hz-ip.png](/u/hz-ip-6FsMg0.png)

5. Now head over to wherever your domain is managed. Some common registrars are <a href="https://www.godaddy.com" target="_blank">GoDaddy</a>, <a href="https://www.namecheap.com" target="_blank">namecheap</a> or <a href="https://www.squarespace.com" target="_blank">Squarespace</a>. Sign in and look for a link to manage your domain. You need to add an `A record` that points to the IP you copied above. It'll look something like this: ![DO-a-record.png](/u/do-a-record-TBoVla.png)

6. Next, head back over to Hetzner and open the Console to connect to your server.   ![hz-console-menu.png](/u/hz-console-menu-yPBmdi.png)

7. Finally, find the install command in the confirmation email we sent you and paste it into the command line: ![do-cli.png](/u/do-cli-QqIe5C.png)

8. You'll be asked which domain name you will be using. That needs to be the same as the A record you set up in your domain manager. Type it in and ONCE will handle the rest. A few minutes later you'll see something like this: ![installation.png](/u/installation-qJ6Wol.png)

9. You're done! Open the URL in your web browser and set up your Writebook account.
