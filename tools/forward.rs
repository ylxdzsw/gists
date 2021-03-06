// Usage: forward 3000:4000 <remote_ip>:22

// [dependencies]
// rlimit = "0.4"
// futures = "0.3"
// tokio = { version = "0.2", features = ["rt-core", "tcp", "macros", "io-util"] }

#[tokio::main]
async fn main() {
    let args: Vec<_> = std::env::args().collect();
    let a: Vec<_> = args[1].split(':').collect();
    let b = &args[2];

    let p_start: u16 = a[0].parse().unwrap();
    let p_end: u16 = a[1].parse().unwrap();

    setulimit(((p_end - p_start) as u64) + 200);

    let handles = (p_start..=p_end).map(|i| tokio::spawn(l(i, b.clone())) );
    futures::future::join_all(handles).await;
}

async fn l(port: u16, dest: String) {
    let mut listener = tokio::net::TcpListener::bind(std::net::SocketAddr::new("0.0.0.0".parse().unwrap(), port)).await.unwrap();
    loop {
        let (socket, _) = listener.accept().await.unwrap();
        if let Ok(dest) = tokio::net::TcpStream::connect(dest.parse::<std::net::SocketAddr>().unwrap()).await {
            tokio::spawn(bicopy(socket, dest));
        } else {
            eprintln!("connection to destination failed");
        }
    }
}

async fn bicopy(mut c1: tokio::net::TcpStream, mut c2: tokio::net::TcpStream) {
    let (mut r1, mut w1) = c1.split();
    let (mut r2, mut w2) = c2.split();
    let _ = tokio::join!(
        tokio::io::copy(&mut r1, &mut w2),
        tokio::io::copy(&mut r2, &mut w1),
    );
}

fn setulimit(x: u64) {
    let res = rlimit::Resource::NOFILE;
    let (soft, hard) = rlimit::getrlimit(res).unwrap();
    if x > hard {
        panic!("hard ulimit is not enough");
    }
    assert!( res.set(std::cmp::max(soft, x), hard).is_ok() );
}
