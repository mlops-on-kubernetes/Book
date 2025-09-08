<div align="right">
  <a href="https://github.com/mlops-on-kubernetes/Book">
    <img src="https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png" alt="GitHub" width="32" height="32">
  </a>
</div>

# Real-world ML systems with Kubernetes

<div align="center">
  <img src="Images/Book-Image-2.jpg" alt="Real-world ML systems with Kubernetes Book Cover" width="800" style="border-radius: 15px; box-shadow: 0 10px 30px rgba(0,0,0,0.3); margin: 30px 0;"/>
  <p>Pier60 Clearwater Beach, Florida</p>
</div>

## About This Book

Machine learning is no longer a research project–it's infrastructure. It's operations. It's pipelines, training, and inference. From recommending what to watch next to flagging fraudulent transactions, ML systems have become core components of modern software. But while building a model in a notebook is straightforward, scaling and deploying that model reliably in production is where most teams fail. According to Gartner, up to 85% of ML projects never reach their intended impact. Why? Because the hardest part isn't the model, it's everything around it.

Operationalizing machine learning means taking a promising prototype and integrating it into a system that can scale, recover from failure, adapt to new data, and stay performant over time. This transition demands much more than good models; it requires disciplined engineering across infrastructure, deployment, monitoring, and data pipelines. This is where MLOps comes in. MLOps is the intersection of machine learning, software engineering, and DevOps, a set of practices and tools that help teams build, deploy, and maintain ML systems at scale. And today, the most versatile platform for building MLOps infrastructure is Kubernetes.

This book teaches you how to design and operate scalable ML systems using Kubernetes. You'll learn the tools, patterns, and architectural principles needed to move machine learning beyond experimentation and into production safely, reliably, and repeatably. Whether you're building an internal platform or scaling an AI product, Kubernetes gives you the foundation to operationalize machine learning like software.

## What You'll Learn

This book covers the essential topics for building production-ready ML systems on Kubernetes:

- **Accelerating machine learning innovation using MLOps and Kubernetes**  
- **Fundamentals of Kubernetes**  
- **Building an ML Platform on Kubernetes**  
- **Scalable Data Pipelines with Kubernetes**  
- **Training Machine Learning Models on Kubernetes**  
- **Distributed Computing with Ray and Kubernetes**  
- **Operationalizing ML Models with Kubernetes**  
- **Serving LLMs on Kubernetes**  
- **Observing ML Applications in Kubernetes**

## Open Source & Support

We are open sourcing this book to make MLOps knowledge accessible to everyone. You can find the complete book content with PDF version in this repository - Book.pdf will be added soon!

If you find this book valuable and would like to support our work, you can purchase the Kindle edition: [📚 Available on Amazon Kindle](https://www.amazon.com/gp/product/B0FQ4BFHLV/ref=kinw_myk_ro_title)

# Acknowledgements

## Re Alvarez Parmar

<div align="center">
  <img src="Images/Re Alvarez Parmar.png" alt="Re Alvarez Parmar" width="300" style="border-radius: 10px; margin: 20px 0;"/>
</div>

I'd like to thank my family for letting me write this book. Without them nothing will be possible.

At AWS, I'd like to thank so many colleagues, including, Jafar Shameem, Rohit Arora, Anish Kantawala, Michael Hausenblas, Apoorva Kulkarni, Vara Bonthu, Florian Stahl, Simon Reichert and all the contributors to the Data/AI on EKS project.

## Elamaran Shanmugam

<div align="center">
  <img src="Images/Elamaran Shanmugam.png" alt="Elamaran Shanmugam" width="300" style="border-radius: 10px; margin: 20px 0;"/>
</div>

As I reflect on the journey of writing this book, I am filled with gratitude for all those who have supported me along the way. This book represents not just my technical knowledge, but also the culmination of countless interactions, learning experiences, and support from numerous individuals who have contributed to its creation.

First and foremost, I want to express my deepest gratitude to my family - my loving wife Nila, and my wonderful children Shivani and Theju. Their unwavering support and understanding as I dedicated countless evenings and weekends to this project has been the foundation of my success. Nila's patience during long writing sessions, her encouragement during moments of doubt, and her willingness to take on extra responsibilities to give me the time and space to work have been invaluable. My children's understanding when I missed family time and their bright smiles that kept me going have meant the world to me. This book is as much a testament to their love and support as it is to my efforts.

Special thanks to my colleagues at Amazon who provided invaluable guidance and reviewed my approaches and architectures throughout this book. Their expertise in cloud computing, machine learning, and Kubernetes has been instrumental in refining my ideas and ensuring the accuracy and relevance of my content. The time they took from their busy schedules to offer insights, challenge my assumptions, and share real-world experiences has significantly enhanced the quality and practicality of this book. Their contributions have made this work not just mine, but a collaborative effort reflecting the collective knowledge of our Kubernetes and Machine Learning community.

I am indebted to my friends who served as my steadfast cheerleaders, offering constant encouragement and motivation throughout this journey. Their genuine interest in my progress, their willingness to listen to my ideas (even when they were highly technical), and words of encouragement during challenging times kept me going. They reminded me of the importance of my work when I was too close to see it, and celebrated my milestones, no matter how small. Their friendship and support have been a source of strength and inspiration throughout this process.

My gratitude extends to the vibrant open-source communities, particularly Ray, MLFlow, Spark, Kubeflow and others, whose innovations have inspired much of my work. The spirit of collaboration and knowledge-sharing in these communities has been a guiding light for me. I've built upon the foundations they have laid, and I hope this book contributes back to the collective knowledge pool.

I also acknowledge the authors whose books on related topics have influenced my perspective and approach. Their works have been my teachers, challenging me to think deeper and strive for clarity in my explanations. The insights I've gained from their writings have shaped my understanding of the field and influenced how I've chosen to present complex topics.

Finally, I want to recognize the wealth of knowledge shared through various online platforms including Medium, GitHub, and Reddit. These resources have been an invaluable source of cutting-edge information, practical tips, and real-world experiences. The discussions, code snippets, and articles I found on these platforms helped me refine my technical demonstrations and elevate the overall quality of my work. The global community of developers and data scientists who freely share their knowledge have been silent contributors to this book, and I am deeply appreciative of their collective wisdom.

# About the Authors

## Elamaran (Ela) Shanmugam

Elamaran (Ela) Shanmugam is a Sr. Specialist Solutions Architect with Amazon Web Services with over 20 years of experience in architecting, developing and day 2 operations of large scale enterprise systems and applications. Ela helps AWS customers and partners to build products and services using modern technologies to enable their business. Ela is a Container, App Modernization, Observability, Generative AI and Machine Learning SME and helps AWS partners and customers design and build scalable, secure, and optimized workloads on AWS. Being a Sr. technologist, Ela's focus is on modern application development, cloud migration, modernization and automation. Being at AWS, Ela enjoys contributing to open source, public speaking, mentoring, and publishing engaging technical content such as AWS Whitepapers, AWS Blogs, Internal articles. Ela is based out of Tampa, Florida, and you can reach Ela on Twitter @IamElaShan and elamaran11 on GitHub.

## Re Alvarez Parmar

Re Alvarez Parmar has spent over two decades architecting, building, and operating enterprise systems and infrastructure. In his current role at AWS as Principal Solutions Architect, he helps some of most the sophisticated Automotive companies modernize and scale their software architecture using cloud. His focus over the past few years has been cloud-native architecture, modern application development, and distributed systems.
