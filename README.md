# LearnRxImageSummary

Similar to [LearnRxUserSuggestion](https://github.com/EDFward/LearnRxUserSuggestion), this is my another attempt to learn functional reactive programming. 

This time I used [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa) in Swift to build a toy Mac OS app, which could extract image keywords from a picture, using [AlchemyAPI](http://www.alchemyapi.com/) (called *Image Tagging* under *AlchemyVision*).

Here are screenshots of the app:

![screenshot2](http://imgur.com/qVBhn45.png)
![screenshot1](http://imgur.com/4XWNo0H.png)

The basic idea is simple - user clicks of the *upload* are a signal / stream / observable (let's agree to call them *streams* anyway), leading to image data stream, URL request stream and analysis result stream. Combine them in some way and the app logic comes naturally.

It turns out the most time-consuming task is not about the logic or even the code, but the layout issues...I hate Auto Layout!