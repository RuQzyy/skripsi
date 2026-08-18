<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - Smart Attendance System</title>

    @vite(['resources/css/app.css','resources/js/app.js'])

    <style>
        :root{
            --color-darkest:#0A1931;
            --color-medium-dark:#1A3D63;
            --color-medium:#4A7FA7;
            --color-light:#B3CFE5;
            --color-lightest:#F6FAFD;
        }

        body{
            margin:0;
            padding:0;
            min-height:100vh;
            display:flex;
            justify-content:center;
            align-items:center;
            background:linear-gradient(
                rgba(10,25,49,.85),
                rgba(26,61,99,.85)
            ),
            url("https://images.unsplash.com/photo-1509062522246-3755977927d7");
            background-size:cover;
            background-position:center;
            font-family:'Segoe UI',sans-serif;
        }

        .login-container{
            width:1000px;
            max-width:95%;
            min-height:550px;
            background:white;
            border-radius:20px;
            overflow:hidden;
            display:flex;
            box-shadow:0 20px 40px rgba(10,25,49,.25);
        }

        .left-side{
            width:45%;
            background:
                linear-gradient(
                    rgba(10,25,49,.85),
                    rgba(26,61,99,.85)
                ),
                url("https://images.unsplash.com/photo-1523050854058-8df90110c9f1");
            background-size:cover;
            background-position:center;
            color:white;
            display:flex;
            flex-direction:column;
            justify-content:center;
            align-items:center;
            padding:40px;
            text-align:center;
        }

        .left-side img{
            width:120px;
            margin-bottom:20px;
        }

        .left-side h1{
            font-size:30px;
            font-weight:bold;
            margin-bottom:10px;
        }

        .left-side p{
            opacity:.9;
        }

        .right-side{
            width:55%;
            display:flex;
            justify-content:center;
            align-items:center;
            padding:40px;
        }

        .login-form{
            width:100%;
            max-width:380px;
        }

        .login-form h2{
            font-size:38px;
            color:var(--color-darkest);
            margin-bottom:5px;
        }

        .login-form p{
            color:#9ca3af;
            margin-bottom:30px;
        }

        .input-group{
            margin-bottom:20px;
        }

        .input-group label{
            display:block;
            margin-bottom:8px;
            font-size:14px;
            color:#4b5563;
        }

        .input-group input{
            width:100%;
            padding:14px;
            border:1px solid #d1d5db;
            border-radius:50px;
            outline:none;
            transition:border-color .2s;
        }

        .input-group input:focus{
            border-color:var(--color-medium-dark);
        }

        .login-btn{
            width:100%;
            border:none;
            padding:14px;
            border-radius:50px;
            background:linear-gradient(
                135deg,
                var(--color-darkest),
                var(--color-medium-dark)
            );
            color:white;
            font-size:16px;
            font-weight:600;
            cursor:pointer;
            transition:.3s;
        }

        .login-btn:hover{
            background:var(--color-darkest);
        }

        .error{
            color:#e53935;
            font-size:13px;
            margin-top:5px;
        }

        @media(max-width:768px){

            .login-container{
                flex-direction:column;
            }

            .left-side,
            .right-side{
                width:100%;
            }

            .left-side{
                min-height:250px;
            }
        }
    </style>
</head>
<body>

<div class="login-container">

    {{-- KIRI --}}
    <div class="left-side">

        {{-- Ganti dengan logo SMA 15 Ambon --}}
        <img src="{{ asset('images/logo.png') }}" alt="Logo">

        <h1>Smart Attendance System</h1>

        <p>
            Sistem Absensi Berbasis Face Recognition
            <br>
            SMA 15 Ambon
        </p>

    </div>

    {{-- KANAN --}}
    <div class="right-side">

        <form method="POST"
              action="{{ route('login') }}"
              class="login-form">

            @csrf

            <h2>Welcome</h2>

            <p>
                Login untuk melanjutkan ke dashboard admin
            </p>

            <div class="input-group">
                <label>Email</label>

                <input
                    type="email"
                    name="email"
                    value="{{ old('email') }}"
                    required
                    autofocus
                >

                @error('email')
                    <div class="error">{{ $message }}</div>
                @enderror
            </div>

            <div class="input-group">
                <label>Password</label>

                <input
                    type="password"
                    name="password"
                    required
                >

                @error('password')
                    <div class="error">{{ $message }}</div>
                @enderror
            </div>

            <button type="submit" class="login-btn">
                Login
            </button>

        </form>

    </div>

</div>

</body>
</html>
