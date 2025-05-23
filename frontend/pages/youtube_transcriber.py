import streamlit as st
import requests
import json
import time
import os

# Get API URLs from environment variables or use defaults
ML_SERVICE_URL = os.environ.get("ML_SERVICE_URL", "http://localhost:5000")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "codexcontinue")

st.set_page_config(
    page_title="YouTube Transcriber - CodexContinue",
    page_icon="🎬",
    layout="wide"
)

# Title and introduction
st.title("🎬 YouTube Video Transcriber")
st.markdown("""
This tool allows you to transcribe YouTube videos to text and optionally summarize the content.
Simply paste a YouTube URL below and click 'Transcribe'.
""")

# Input form
with st.form("youtube_form"):
    youtube_url = st.text_input("YouTube URL", placeholder="https://www.youtube.com/watch?v=...")
    
    col1, col2 = st.columns(2)
    with col1:
        language = st.selectbox("Language (optional)", 
                           [None, "English", "Spanish", "French", "German", "Italian", 
                            "Portuguese", "Russian", "Chinese", "Japanese", "Korean"])
    with col2:
        whisper_model = st.selectbox("Whisper Model", 
                                   ["tiny", "base", "small", "medium", "large"], 
                                   index=1,
                                   help="Larger models are more accurate but take longer to process")
    
    col1, col2 = st.columns(2)
    with col1:
        transcribe_button = st.form_submit_button("🔊 Transcribe")
    with col2:
        transcribe_and_summarize = st.form_submit_button("📝 Transcribe & Summarize")

# Create tabs for different sections
if transcribe_button or transcribe_and_summarize:
    tab1, tab2, tab3 = st.tabs(["Video", "Transcript", "Summary"])
    
    if not youtube_url:
        st.error("Please enter a YouTube URL")
    else:
        with st.spinner("Processing YouTube video... This may take a few minutes depending on video length."):
            # Call the ML service API
            try:
                response = requests.post(
                    f"{ML_SERVICE_URL}/youtube/transcribe",
                    json={
                        "url": youtube_url, 
                        "language": language,
                        "generate_summary": transcribe_and_summarize
                    }
                )
                
                if response.status_code == 200:
                    result = response.json()
                    transcript_text = result["text"]
                    
                    # Display success notification
                    st.success("Transcription completed successfully!")
                    
                    # Display video in the video tab
                    with tab1:
                        st.subheader("Video")
                        video_id = youtube_url.split("v=")[1].split("&")[0] if "v=" in youtube_url else youtube_url.split("/")[-1]
                        st.video(f"https://www.youtube.com/watch?v={video_id}")
                    
                    # Display the transcript in the transcript tab
                    with tab2:
                        st.subheader("Transcript")
                        
                        # Show transcript metadata
                        segments = result.get("segments", [])
                        col1, col2 = st.columns(2)
                        with col1:
                            st.metric("Total Segments", len(segments))
                        with col2:
                            total_duration = segments[-1]["end"] if segments else 0
                            st.metric("Duration", f"{total_duration:.2f} seconds")
                        
                        # Display the full transcript
                        st.text_area("Full Transcript", transcript_text, height=400)
                        
                        # Download button for transcript
                        st.download_button(
                            label="Download Transcript",
                            data=transcript_text,
                            file_name="transcript.txt",
                            mime="text/plain"
                        )
                        
                        # Optional: Display segment details in an expander
                        with st.expander("View Transcript Segments"):
                            for i, segment in enumerate(segments):
                                st.markdown(f"**{i+1}. [{segment['start']:.2f}s - {segment['end']:.2f}s]:** {segment['text']}")
                    
                    # Handle summary in the summary tab
                    with tab3:
                        st.subheader("Summary")
                        
                        if transcribe_and_summarize and "summary" in result:
                            summary_data = result["summary"]
                            summary_text = summary_data.get("summary", "")
                            
                            if summary_data.get("error"):
                                st.error(summary_text)
                            else:
                                # Show the model used
                                st.info(f"Summary generated using model: {summary_data.get('model', OLLAMA_MODEL)}")
                                
                                # Display the summary
                                st.markdown(summary_text)
                                
                                # Download button for summary
                                st.download_button(
                                    label="Download Summary",
                                    data=summary_text,
                                    file_name="summary.txt",
                                    mime="text/plain"
                                )
                        else:
                            st.info("No summary was requested. Use the 'Transcribe & Summarize' button to generate a summary.")
                else:
                    st.error(f"Error: {response.text}")
            except Exception as e:
                st.error(f"Error processing request: {str(e)}")
                st.info("Make sure the ML service is running and accessible.")
else:
    # Display some instructions when the page first loads
    st.info("Enter a YouTube URL above and click 'Transcribe' to get started.")
    
    # Display a collapsible section with more information
    with st.expander("About this feature"):
        st.markdown("""
        ### How it works
        
        1. **Download**: The tool downloads the audio from the YouTube video
        2. **Transcribe**: OpenAI's Whisper model transcribes the audio to text
        3. **Summarize** (optional): Ollama can summarize the transcript if requested
        
        ### Tips
        
        - For best results, choose the appropriate language if you know it
        - Longer videos will take more time to process
        - The 'base' Whisper model is a good balance between speed and accuracy
        """)

# Add a sidebar with information
with st.sidebar:
    st.header("About this tool")
    st.markdown("""
    This tool uses:
    - **yt-dlp** to download YouTube audio
    - **Whisper** for speech-to-text transcription
    - **Ollama** with LLaMA 3 for summarization
    
    For longer videos, the transcription process may take several minutes.
    """)
    
    st.header("Tips")
    st.markdown("""
    - For best results, use videos with clear audio
    - Shorter videos (under 10 minutes) process faster
    - The summarization works best with structured content
    """)
