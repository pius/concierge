Meteor + Tagstand NFC-based checkin system 
============
> Code and documentation by [Pius Uzamere](http://pius.me)

*****

[Concierge](http://github.com/pius/concierge) is a proof-of-concept maître d' or concierge dashboard I hacked together one evening that uses an awesome real-time web app framework called [Meteor](http://www.meteor.com) and the very cool [Tagstand TAP NFC reader](http://tap.tagstand.com/). Guests "checkin" with an NFC tag that's 
been associated with their account, causing their picture and details to instantly popup on the screen.

The simplicity of the Tagstand TAP NFC reader and the reactive paradigm of Meteor worked together beautifully to let me implement this prototype in 40 lines of code (HTML and documentation notwithstanding).

    author = "Pius Uzamere"

 We begin by setting up the collections of objects. 

 Supporting the association of NFC tags with guests through the UI is left as an [exercise to the reader](http://github.com/pius/concierge); I [did it by hand](http://docs.meteor.com/#dataandsecurity).
    Guests = new Meteor.Collection("guests")
    Checkins = new Meteor.Collection("checkins")


Accepting POST Requests
---------

The Tagstand TAP NFC reader [POSTs](http://tools.ietf.org/html/rfc2616#section-9.5) a JSON payload to an endpoint we choose anytime it comes in contact with an NFC tag.
Let's set up an endpoint that will create a checkin object every time our NFC reader pings it.

We've installed [Meteor Router](https://github.com/tmeasday/meteor-router), which allows us to do a certain amount of server-side routing.

    if Meteor.isServer
      Meteor.Router.add "/checkins", "POST", ->

For simplicity's sake, we're blithely trusting this input without any verification or other security. 
Implementing appropriate security is left as an exercise for the reader.

        checkin = @request.body

        Checkins.insert checkin, (error, result) ->
          if error
            console.log "checkin creation failed with error #{error}"
            [500, "Checkin creation failed"]
          else
            console.log "result of checkin insertion is #{result}"
            [204, "No Content"]


Publishing and Subscribing to Collections
---------

The final thing we need to do on the server side is publish the collections we've created. 
For simplicity's sake, we'll publish the entirety of each collection to the client.

      Meteor.publish "checkins", ->
        Checkins.find()

      Meteor.publish "guests", ->
        Guests.find()

On the client, let's start by subscribing to the two collections we've published.

    if Meteor.isClient
      Meteor.subscribe "checkins"
      Meteor.subscribe "guests"

Template Methods
---------

Next, we're going to expose the data we need for our templates. We've defined two templates: 
checkins (for showing the latest guest checkins), checkin (used to show an individual guest 
checkin), and guest_detail (used, unsurprisingly, to show data about a specific guest).

For the checkins template, all we'll need to expose is the list of the 10 latest checkins.

      Template.checkins.checkins = ->
        checkins = Checkins.find
          tapped_at:
            $ne: null
        ,
          sort:
            tapped_at: -1
          limit: 10
        checkins.fetch()

For the checkin template, let's begin by exposing a relative date to show our users how long ago the
guest checked in, rather than showing an ugly timestamp. We'll use the excellent Moment.JS to make 
this easy.

      Template.checkin.relative_date = ->
        format_string = 'YYYY-MM-DD h:mm:ss [UTC]'
        now = moment.utc()
        moment.utc(@tapped_at, format_string).from now

The main data we want to expose for the checkin template is the guest associated with the checkin.
In a way, this is where the proverbial magic happens. We query our database to find the guest with 
whom the NFC tag is associated. Thankfully, this is pretty trivial to do.
 
      Template.checkin.guest = ->
        Guests.findOne({tag: @uuid}) || {photo: "question.png", name: "Unknown Guest"}

Last, but not least, the guest detail template. All we need to expose is the guest object. 
We'll use a Session variable representing the selected guest id to find the correct guest. 

A Session variable is a good choice here because the Session is reactive, meaning that changes to it 
will immediately cause templates that rely upon it to re-render with the new context.

      Template.guest_detail.guest = ->
        guest = Guests.findOne Session.get("selected")
        guest = guest ? guest : {photo: "question.png", name: "Unknown Guest"}


Events
---------

Our final bit of code is to define an event on the checkin template that will allow us to click on
a guest photo or name and see more information about that guest. When the user clicks on an element
of class "viewGuest" we'll set our Session variable to the selected guests's id.

Note that rather than writing some sort of callback to manually manipulate the DOM or render a template, 
we are trusting the guest_detail template to update itself. We are eliminating unnecessary work for 
ourselves by leveraging the reactivity of the Session variable.

      Template.checkin.events
        'click .viewGuest': ->
          Session.set("selected", Guests.findOne({tag:@uuid})._id)

And that's it. The rest is HTML templating to implement the views. See concierge.jade for more information.

