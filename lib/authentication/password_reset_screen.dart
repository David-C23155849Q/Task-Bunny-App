import 'package:errand_app/authentication/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResetScreen extends StatefulWidget {
  const ResetScreen({super.key});

  @override
  State<ResetScreen> createState() => _ResetScreenState();
}

class _ResetScreenState extends State<ResetScreen>
{
  TextEditingController resetPasswordTextEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          //app logo
          Image.asset(
            "assets/images/ulogo2.png",
            width: MediaQuery.of(context).size.width * .6,
          ),

          const SizedBox(height: 22,),

          Text("Reset Password",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: resetPasswordTextEditingController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Enter Your Email",
                labelStyle: TextStyle(
                  fontSize: 14,
                ),
              ),
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
          ),

          const SizedBox(height: 22,),
          //text about what will happen
          Text("Password reset link will be send to your email",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: Colors.white
            ),
          ),


          const SizedBox(height: 22,),
          ElevatedButton(
              onPressed: () async
              {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: resetPasswordTextEditingController.text.trim()).then((value)
                {
                  Navigator.push(context, MaterialPageRoute(builder: (c)=> LoginScreen()));
                });
              },
              child: Text("Reset Password"),
          ),
        ],
      ),
    );
  }
}
