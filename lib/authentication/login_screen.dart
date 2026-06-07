import 'package:errand_app/authentication/password_reset_screen.dart';
import 'package:errand_app/authentication/signup_screen.dart';
import 'package:errand_app/global/global_var.dart';
import 'package:errand_app/methods/common_methods.dart';
import 'package:errand_app/pages/errand_design_page.dart';
import 'package:errand_app/pages/main_screen.dart';
//import 'package:errand_app/pages/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../pages/home_page.dart';
import '../widgets/loading_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  CommonMethods cMethods = CommonMethods();

  checkIfNetworkIsAvailble()
  {
    cMethods.checkConnectivity(context);

    signInFormValidation();
  }

  signInFormValidation()
  {
    if(emailTextEditingController.text.trim().length < 3)
    {
      cMethods.displaySnackBar("Username must be atleast 4 or more characters.", context);
    }
    else if(passwordTextEditingController.text.trim().length < 6)
    {
      cMethods.displaySnackBar("Password is incorrect", context);
    }
    else
    {
      //login user
      signInUser();
    }
  }

  signInUser() async
  {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => LoadingDialog(messageText: "Loading"),
    );

    final User? userFirebase = (
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailTextEditingController.text.trim(),
          password: passwordTextEditingController.text.trim(),
        ).catchError((errorMsg)
        {
          Navigator.pop(context);
          cMethods.displaySnackBar(errorMsg.toString(), context);
        })
    ).user;

    if(!context.mounted) return;
    Navigator.pop(context);

    if(userFirebase!= null)
      {
        DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("users").child(userFirebase!.uid);
        await usersRef.once().then((snap)
        {
          if(snap.snapshot.value != null)
            {
              if((snap.snapshot.value as Map)["blockStatus"] == "no")
                {
                  userName = (snap.snapshot.value as Map)["name"];
                  Navigator.push(context, MaterialPageRoute(builder: (c)=> HomePage()));
                }
              else
              {
                FirebaseAuth.instance.signOut();
                cMethods.displaySnackBar("Account blocked.Contact admin: davidsithole2023@gmail.com", context);
              }
            }
          else
            {
              FirebaseAuth.instance.signOut();
              cMethods.displaySnackBar("Account does not exist.", context);
            }
        });
      }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [

              const SizedBox(height: 122,),

              Image.asset(
                  "assets/images/ulogo2.png",
                  width: MediaQuery.of(context).size.width * .6,
              ),

              const Text(
                "Login",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              //my text fields and button
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [


                    TextField(
                      controller: emailTextEditingController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        labelStyle: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 22,),

                    TextField(
                      controller: passwordTextEditingController,
                      obscureText: true,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: "Password",
                        labelStyle: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 1,),


                    TextButton(
                      onPressed:()
                      {
                        Navigator.push(context, MaterialPageRoute(builder: (c)=> ResetScreen()));
                      },
                      child: const Text(
                        "Reset Password",
                        style: TextStyle(
                            color: Colors.green
                        ),
                      ),
                    ),

                    const SizedBox(height: 22,),

                    ElevatedButton(
                      onPressed: ()
                      {
                        checkIfNetworkIsAvailble();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(horizontal: 80)
                      ),
                      child: const Text(
                          "Login"
                      ),
                    ),

                  ],
                ),
              ),


              const SizedBox(height: 6,),

              //text button to login page
              TextButton(
                onPressed:()
                {
                  Navigator.push(context, MaterialPageRoute(builder: (c)=> SignupScreen()));
                },
                child: const Text(
                  "Don`t have an Account? Sign Up",
                  style: TextStyle(
                      color: Colors.green
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
